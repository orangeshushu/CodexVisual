using System;
using System.Globalization;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using WpfButton = System.Windows.Controls.Button;
using WpfColor = System.Windows.Media.Color;
using WpfProgressBar = System.Windows.Controls.ProgressBar;

namespace CodexVisual.Windows;

internal sealed class QuotaPopupWindow : Window
{
    private readonly TextBlock _planText = new();
    private readonly QuotaCard _fiveHourCard = new(AppText.FiveHourQuota);
    private readonly QuotaCard _sevenDayCard = new(AppText.SevenDayQuota);
    private readonly TextBlock _sourceText = new();
    private readonly TextBlock _lastReadText = new();
    private readonly TextBlock _errorText = new();
    private readonly StackPanel _contentStack = new();
    private readonly WpfButton _refreshButton = new() { Content = AppText.RefreshNow };
    private readonly WpfButton _updateButton = new() { Content = AppText.CheckForUpdates };
    private readonly WpfButton _exitButton = new() { Content = AppText.Exit };

    public event EventHandler? RefreshRequested;
    public event EventHandler? ExitRequested;

    public QuotaPopupWindow()
    {
        Title = AppText.AppTitle;
        Width = 430;
        Height = 430;
        ResizeMode = ResizeMode.NoResize;
        ShowInTaskbar = false;
        WindowStartupLocation = WindowStartupLocation.Manual;
        Background = Brushes.White;
        TrySetWindowIcon();

        var root = new Border
        {
            Padding = new Thickness(16),
            Background = Brushes.White,
            Child = _contentStack
        };

        _contentStack.Orientation = Orientation.Vertical;
        _contentStack.Children.Add(new TextBlock
        {
            Text = AppText.AppTitle,
            FontSize = 20,
            FontWeight = FontWeights.SemiBold,
            Foreground = new SolidColorBrush(Color.FromRgb(17, 24, 39)),
            Margin = new Thickness(0, 0, 0, 8)
        });

        _planText.FontSize = 13;
        _planText.Foreground = new SolidColorBrush(Color.FromRgb(75, 85, 99));
        _planText.Margin = new Thickness(0, 0, 0, 12);
        _contentStack.Children.Add(_planText);
        _contentStack.Children.Add(_fiveHourCard);
        _contentStack.Children.Add(_sevenDayCard);

        _sourceText.FontSize = 12;
        _sourceText.Foreground = new SolidColorBrush(Color.FromRgb(75, 85, 99));
        _sourceText.TextWrapping = TextWrapping.Wrap;
        _sourceText.Margin = new Thickness(0, 8, 0, 2);
        _contentStack.Children.Add(_sourceText);

        _lastReadText.FontSize = 12;
        _lastReadText.Foreground = new SolidColorBrush(Color.FromRgb(75, 85, 99));
        _lastReadText.TextWrapping = TextWrapping.Wrap;
        _contentStack.Children.Add(_lastReadText);

        _errorText.Visibility = Visibility.Collapsed;
        _errorText.TextWrapping = TextWrapping.Wrap;
        _errorText.Foreground = new SolidColorBrush(Color.FromRgb(185, 28, 28));
        _errorText.Margin = new Thickness(0, 20, 0, 20);
        _contentStack.Children.Add(_errorText);

        _contentStack.Children.Add(BuildButtonRow());
        Content = root;

        _refreshButton.Click += (_, _) => RefreshRequested?.Invoke(this, EventArgs.Empty);
        _updateButton.Click += async (_, _) => await RunUpdateCheck();
        _exitButton.Click += (_, _) => ExitRequested?.Invoke(this, EventArgs.Empty);
    }

    private void TrySetWindowIcon()
    {
        try
        {
            Icon = BitmapFrame.Create(new Uri("pack://application:,,,/app.ico"));
        }
        catch
        {
            // Tray icon extraction has its own fallback for development builds.
        }
    }

    public void ShowNearTray()
    {
        Left = SystemParameters.WorkArea.Right - Width - 12;
        Top = SystemParameters.WorkArea.Bottom - Height - 12;
        Show();
        Activate();
    }

    public void UpdateSnapshot(QuotaSnapshot snapshot)
    {
        _errorText.Visibility = Visibility.Collapsed;
        _fiveHourCard.Visibility = Visibility.Visible;
        _sevenDayCard.Visibility = Visibility.Visible;
        _planText.Visibility = Visibility.Visible;
        _sourceText.Visibility = Visibility.Visible;
        _lastReadText.Visibility = Visibility.Visible;

        var plan = snapshot.Event.PlanType?.ToUpperInvariant() ?? AppText.Unknown;
        _planText.Text = AppText.Plan(plan);
        _fiveHourCard.Update(snapshot.Event.RateLimits.Primary);
        _sevenDayCard.Update(snapshot.Event.RateLimits.Secondary);
        _sourceText.Text = $"{AppText.DataSource}: {snapshot.Source} ({snapshot.SourcePath})";
        _lastReadText.Text = $"{AppText.LastRead}: {FormatDateTime(snapshot.ReadDate)}";
    }

    public void UpdateExpiredSnapshot(QuotaSnapshot snapshot, string message, DateTimeOffset lastRead)
    {
        _errorText.Visibility = Visibility.Visible;
        _fiveHourCard.Visibility = Visibility.Visible;
        _sevenDayCard.Visibility = Visibility.Visible;
        _planText.Visibility = Visibility.Visible;
        _sourceText.Visibility = Visibility.Visible;
        _lastReadText.Visibility = Visibility.Visible;

        var plan = snapshot.Event.PlanType?.ToUpperInvariant() ?? AppText.Unknown;
        _planText.Text = AppText.Plan(plan);
        _fiveHourCard.Update(snapshot.Event.RateLimits.Primary, useLastKnown: true);
        _sevenDayCard.Update(snapshot.Event.RateLimits.Secondary, useLastKnown: true);
        _sourceText.Text = $"{AppText.DataSource}: {snapshot.Source} ({snapshot.SourcePath})";
        _lastReadText.Text = $"{AppText.LastRead}: {FormatDateTime(lastRead)}";
        _errorText.Text = message;
    }

    public void UpdateError(string message, DateTimeOffset lastRead)
    {
        _fiveHourCard.Visibility = Visibility.Collapsed;
        _sevenDayCard.Visibility = Visibility.Collapsed;
        _planText.Visibility = Visibility.Collapsed;
        _sourceText.Visibility = Visibility.Visible;
        _lastReadText.Visibility = Visibility.Visible;
        _errorText.Visibility = Visibility.Visible;
        _errorText.Text = string.IsNullOrWhiteSpace(message) ? AppText.NoQuotaYet : message;
        _sourceText.Text = $"{AppText.DataSource}: {AppText.CodexLogs}";
        _lastReadText.Text = $"{AppText.LastRead}: {FormatDateTime(lastRead)}";
    }

    private async Task RunUpdateCheck()
    {
        _updateButton.IsEnabled = false;
        _updateButton.Content = AppText.CheckingUpdates;
        try
        {
            await UpdateChecker.CheckAsync(this);
        }
        finally
        {
            _updateButton.Content = AppText.CheckForUpdates;
            _updateButton.IsEnabled = true;
        }
    }

    private StackPanel BuildButtonRow()
    {
        var row = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            HorizontalAlignment = HorizontalAlignment.Right,
            Margin = new Thickness(0, 14, 0, 0)
        };

        foreach (var button in new[] { _refreshButton, _updateButton, _exitButton })
        {
            button.MinWidth = 92;
            button.Height = 32;
            button.Margin = new Thickness(6, 0, 0, 0);
            row.Children.Add(button);
        }

        return row;
    }

    private static string FormatDateTime(DateTimeOffset value) =>
        AppText.FormatDateTime(value);

    private sealed class QuotaCard : Border
    {
        private readonly TextBlock _remainingText = new();
        private readonly TextBlock _usedText = new();
        private readonly TextBlock _resetText = new();
        private readonly WpfProgressBar _progressBar = new();

        public QuotaCard(string title)
        {
            CornerRadius = new CornerRadius(8);
            BorderBrush = new SolidColorBrush(Color.FromRgb(229, 231, 235));
            BorderThickness = new Thickness(1);
            Background = new SolidColorBrush(Color.FromRgb(249, 250, 251));
            Padding = new Thickness(12);
            Margin = new Thickness(0, 0, 0, 10);

            var stack = new StackPanel { Orientation = Orientation.Vertical };
            Child = stack;

            stack.Children.Add(new TextBlock
            {
                Text = title,
                FontSize = 14,
                FontWeight = FontWeights.SemiBold,
                Foreground = new SolidColorBrush(Color.FromRgb(17, 24, 39)),
                Margin = new Thickness(0, 0, 0, 8)
            });

            var valueGrid = new Grid();
            valueGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            valueGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });

            _remainingText.FontSize = 13;
            _remainingText.FontWeight = FontWeights.SemiBold;
            _usedText.FontSize = 13;
            _usedText.HorizontalAlignment = HorizontalAlignment.Right;
            _usedText.Foreground = new SolidColorBrush(Color.FromRgb(75, 85, 99));

            Grid.SetColumn(_remainingText, 0);
            Grid.SetColumn(_usedText, 1);
            valueGrid.Children.Add(_remainingText);
            valueGrid.Children.Add(_usedText);
            stack.Children.Add(valueGrid);

            _progressBar.Height = 8;
            _progressBar.Maximum = 100;
            _progressBar.Margin = new Thickness(0, 8, 0, 8);
            stack.Children.Add(_progressBar);

            _resetText.FontSize = 12;
            _resetText.Foreground = new SolidColorBrush(Color.FromRgb(75, 85, 99));
            _resetText.TextWrapping = TextWrapping.Wrap;
            stack.Children.Add(_resetText);
        }

        public void Update(QuotaWindow quota, bool useLastKnown = false)
        {
            var remaining = useLastKnown ? quota.LastKnownRemainingPercent : quota.RemainingPercent;
            var used = useLastKnown ? Math.Clamp(quota.UsedPercent, 0, 100) : quota.EffectiveUsedPercent;
            var color = ColorForRemaining(remaining);
            var brush = new SolidColorBrush(color);
            _remainingText.Foreground = brush;
            _progressBar.Foreground = brush;
            _progressBar.Value = remaining;
            _remainingText.Text = $"{AppText.Remaining}: {remaining}%";
            _usedText.Text = $"{AppText.Used}: {used}%";
            _resetText.Text = $"{AppText.ResetTime}: {FormatDateTime(quota.ResetDate)}";
        }

        private static WpfColor ColorForRemaining(int remaining)
        {
            if (remaining > 50)
            {
                return WpfColor.FromRgb(22, 163, 74);
            }

            if (remaining > 20)
            {
                return WpfColor.FromRgb(217, 119, 6);
            }

            return WpfColor.FromRgb(220, 38, 38);
        }
    }
}
