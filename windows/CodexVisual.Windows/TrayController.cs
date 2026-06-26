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
    private QuotaPopupWindow? _window;
    private QuotaSnapshot? _latestSnapshot;
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
        _notifyIcon.Dispose();
        _window?.Close();
    }

    private Forms.ContextMenuStrip BuildContextMenu()
    {
        var menu = new Forms.ContextMenuStrip();
        menu.Items.Add(AppText.OpenWindow, null, (_, _) => ShowWindow());
        menu.Items.Add(AppText.RefreshNow, null, (_, _) => Refresh());
        menu.Items.Add(AppText.CheckForUpdates, null, async (_, _) => await CheckForUpdates());
        menu.Items.Add(new Forms.ToolStripSeparator());
        menu.Items.Add(AppText.Exit, null, (_, _) => Exit());
        return menu;
    }

    private void ShowWindow()
    {
        EnsureWindow();

        if (_latestSnapshot is not null)
        {
            _window!.UpdateSnapshot(_latestSnapshot);
        }
        else
        {
            _window!.UpdateError(AppText.NoQuotaYet, _lastReadAt);
        }

        _window!.ShowNearTray();
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
        _window.Closed += (_, _) => _window = null;
    }

    private async Task CheckForUpdates()
    {
        EnsureWindow();
        _window!.ShowNearTray();
        await UpdateChecker.CheckAsync(_window);
    }

    private void Refresh()
    {
        _lastReadAt = DateTimeOffset.Now;

        try
        {
            var snapshot = _reader.ReadLatest();
            _latestSnapshot = snapshot;
            UpdateTray(snapshot);
            _window?.UpdateSnapshot(snapshot);
        }
        catch (Exception ex)
        {
            _latestSnapshot = null;
            _notifyIcon.Text = Shorten(AppText.StatusPlaceholder);
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
