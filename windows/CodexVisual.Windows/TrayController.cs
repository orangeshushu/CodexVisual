using Forms = System.Windows.Forms;
using System;
using System.Threading.Tasks;
using System.Windows.Threading;
using WpfApplication = System.Windows.Application;

namespace CodexVisual.Windows;

internal sealed class TrayController : IDisposable
{
    private readonly WpfApplication _application;
    private readonly QuotaReader _reader;
    private readonly Forms.NotifyIcon _notifyIcon;
    private readonly DispatcherTimer _timer = new();
    private Forms.ContextMenuStrip? _dashboardMenu;
    private TaskbarStatusWindow? _statusWindow;
    private QuotaPopupWindow? _window;
    private QuotaSnapshot? _latestSnapshot;
    private QuotaSnapshot? _latestExpiredSnapshot;
    private string _latestErrorMessage = AppText.NoQuotaYet;
    private DateTimeOffset _lastReadAt = DateTimeOffset.Now;
    private bool _disposed;

    public TrayController(WpfApplication application, QuotaReader reader)
    {
        _application = application;
        _reader = reader;
        _notifyIcon = new Forms.NotifyIcon
        {
            Icon = IconFactory.CreateTrayIcon(),
            Text = AppText.StatusPlaceholder,
            Visible = false,
            ContextMenuStrip = BuildContextMenu()
        };

        _notifyIcon.MouseUp += (_, args) =>
        {
            if (args.Button == Forms.MouseButtons.Left)
            {
                ShowWindow();
            }
        };

        _timer.Tick += (_, _) => Refresh();
    }

    public void Start()
    {
        _notifyIcon.Visible = true;
        EnsureStatusWindow();
        Refresh();
    }

    public void Dispose()
    {
        if (_disposed)
        {
            return;
        }

        _disposed = true;
        _timer.Stop();
        _notifyIcon.Visible = false;
        _notifyIcon.ContextMenuStrip?.Dispose();
        _notifyIcon.Dispose();
        _dashboardMenu?.Dispose();
        _statusWindow?.Close();
        _window?.Close();
    }

    private Forms.ContextMenuStrip BuildContextMenu()
    {
        var menu = new Forms.ContextMenuStrip();
        menu.Items.Add(AppText.OpenWindow, null, (_, _) => ShowWindow());
        menu.Items.Add(AppText.RefreshNow, null, (_, _) => Refresh());
        menu.Items.Add(AppText.CheckForUpdates, null, async (_, _) => await CheckForUpdates());
        menu.Items.Add(new Forms.ToolStripSeparator());
        menu.Items.Add(BuildLanguageMenu());
        menu.Items.Add(BuildStartupMenuItem());
        menu.Items.Add(new Forms.ToolStripSeparator());
        menu.Items.Add(AppText.Exit, null, (_, _) => Exit());
        return menu;
    }

    private Forms.ToolStripMenuItem BuildLanguageMenu()
    {
        var menu = new Forms.ToolStripMenuItem(AppText.Language);
        menu.DropDownItems.Add(BuildLanguageItem(AppText.SystemLanguage, AppSettings.LanguageSystem));
        menu.DropDownItems.Add(BuildLanguageItem(AppText.Chinese, AppSettings.LanguageChinese));
        menu.DropDownItems.Add(BuildLanguageItem(AppText.English, AppSettings.LanguageEnglish));
        return menu;
    }

    private Forms.ToolStripMenuItem BuildLanguageItem(string label, string language)
    {
        return new Forms.ToolStripMenuItem(label, null, (_, _) => SetLanguage(language))
        {
            Checked = AppSettings.Current.Language == language,
            CheckOnClick = false
        };
    }

    private Forms.ToolStripMenuItem BuildStartupMenuItem()
    {
        return new Forms.ToolStripMenuItem(AppText.StartAtLogin, null, (_, _) => ToggleStartup())
        {
            Checked = StartupManager.IsEnabled(),
            CheckOnClick = false
        };
    }

    private void ShowDashboardMenu()
    {
        _dashboardMenu?.Dispose();
        _dashboardMenu = BuildContextMenu();
        _dashboardMenu.Show(Forms.Cursor.Position);
    }

    private void ShowWindow()
    {
        EnsureWindow();
        _statusWindow?.Hide();

        if (_latestSnapshot is not null)
        {
            _window!.UpdateSnapshot(_latestSnapshot);
        }
        else if (_latestExpiredSnapshot is not null)
        {
            _window!.UpdateExpiredSnapshot(_latestExpiredSnapshot, _latestErrorMessage, _lastReadAt);
        }
        else
        {
            _window!.UpdateError(_latestErrorMessage, _lastReadAt);
        }

        _window!.ShowNearTray();
    }

    private void EnsureStatusWindow()
    {
        if (_statusWindow is not null)
        {
            return;
        }

        _statusWindow = new TaskbarStatusWindow();
        _statusWindow.MenuRequested += (_, _) => ShowDashboardMenu();
        _statusWindow.Closed += (_, _) => _statusWindow = null;
        _statusWindow.Show();
    }

    private void EnsureWindow()
    {
        if (_window is not null)
        {
            return;
        }

        _window = new QuotaPopupWindow();
        _window.RefreshRequested += (_, _) => Refresh();
        _window.ExitRequested += (_, _) => Exit();
        _window.Closed += (_, _) =>
        {
            _window = null;
            _statusWindow?.Show();
            _statusWindow?.Reposition();
        };
    }

    private async Task CheckForUpdates()
    {
        EnsureWindow();
        _window!.ShowNearTray();
        await UpdateChecker.CheckAsync(_window);
    }

    private void SetLanguage(string language)
    {
        AppSettings.Current.Language = language;
        AppSettings.Current.Save();
        AppText.ApplyLanguage();
        RefreshMenus();
        RecreateWindows();
        Refresh();
    }

    private void ToggleStartup()
    {
        try
        {
            StartupManager.SetEnabled(!StartupManager.IsEnabled());
            RefreshMenus();
        }
        catch (Exception ex)
        {
            Forms.MessageBox.Show(ex.Message, AppText.SettingsFailed, Forms.MessageBoxButtons.OK, Forms.MessageBoxIcon.Warning);
        }
    }

    private void RefreshMenus()
    {
        var oldMenu = _notifyIcon.ContextMenuStrip;
        _notifyIcon.ContextMenuStrip = BuildContextMenu();
        oldMenu?.Dispose();
    }

    private void RecreateWindows()
    {
        _window?.Close();
        _window = null;
        _statusWindow?.Close();
        _statusWindow = null;
        EnsureStatusWindow();
    }

    private void Refresh()
    {
        _lastReadAt = DateTimeOffset.Now;

        try
        {
            var snapshot = _reader.ReadLatest();
            _latestSnapshot = snapshot;
            _latestExpiredSnapshot = null;
            _latestErrorMessage = "";
            UpdateTray(snapshot);
            _window?.UpdateSnapshot(snapshot);
        }
        catch (QuotaExpiredException ex)
        {
            _latestSnapshot = null;
            _latestExpiredSnapshot = ex.Snapshot;
            _latestErrorMessage = ex.Message;
            UpdateExpiredTray(ex.Snapshot);
            _window?.UpdateExpiredSnapshot(ex.Snapshot, ex.Message, _lastReadAt);
        }
        catch (Exception ex)
        {
            _latestSnapshot = null;
            _latestExpiredSnapshot = null;
            _latestErrorMessage = ex.Message;
            _notifyIcon.Text = Shorten(AppText.StatusPlaceholder);
            _statusWindow?.SetStatus(AppText.StatusPlaceholder, null);
            _window?.UpdateError(ex.Message, _lastReadAt);
        }

        ScheduleNextRefresh();
    }

    private void UpdateTray(QuotaSnapshot snapshot)
    {
        var primary = snapshot.Event.RateLimits.Primary;
        var secondary = snapshot.Event.RateLimits.Secondary;
        var title = $"Codex {primary.RemainingPercent} / {secondary.RemainingPercent}%";
        _notifyIcon.Text = Shorten(title);
        _statusWindow?.SetStatus(title, Math.Min(primary.RemainingPercent, secondary.RemainingPercent));
    }

    private void UpdateExpiredTray(QuotaSnapshot snapshot)
    {
        var primary = snapshot.Event.RateLimits.Primary;
        var secondary = snapshot.Event.RateLimits.Secondary;
        var title = $"Last {primary.LastKnownRemainingPercent} / {secondary.LastKnownRemainingPercent}%";
        _notifyIcon.Text = Shorten(title);
        _statusWindow?.SetStatus(title, null);
    }

    private void ScheduleNextRefresh()
    {
        _timer.Stop();
        var interval = NextRefreshInterval();
        _timer.Interval = interval;
        _timer.Start();
    }

    private TimeSpan NextRefreshInterval()
    {
        var seconds = 15.0;
        if (_latestSnapshot is not null)
        {
            foreach (var resetDate in new[]
            {
                _latestSnapshot.Event.RateLimits.Primary.ResetDate,
                _latestSnapshot.Event.RateLimits.Secondary.ResetDate
            })
            {
                var untilReset = (resetDate - DateTimeOffset.Now).TotalSeconds;
                if (untilReset > 0 && untilReset < seconds)
                {
                    seconds = Math.Max(2, untilReset + 2);
                }
            }
        }

        return TimeSpan.FromSeconds(seconds);
    }

    private void Exit()
    {
        Dispose();
        _application.Shutdown();
    }

    private static string Shorten(string value)
    {
        const int maxNotifyTextLength = 63;
        return value.Length <= maxNotifyTextLength ? value : value[..maxNotifyTextLength];
    }
}
