using System;
using System.Globalization;
using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using Forms = System.Windows.Forms;

namespace CodexVisual.Windows;

internal sealed class TaskbarStatusWindow : Window
{
    private static readonly string PositionPath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
        "CodexVisual",
        "windows-dashboard-position.txt");

    private readonly Border _root = new();
    private readonly TextBlock _statusText = new();
    private Point _mouseDownPoint;
    private bool _isDragging;
    private bool _ignoreNextClick;
    private bool _hasCustomPosition;

    public event EventHandler? MenuRequested;

    public TaskbarStatusWindow()
    {
        Width = 150;
        Height = 42;
        ResizeMode = ResizeMode.NoResize;
        WindowStyle = WindowStyle.None;
        ShowInTaskbar = false;
        Topmost = true;
        Background = Brushes.Transparent;
        AllowsTransparency = true;
        WindowStartupLocation = WindowStartupLocation.Manual;

        _root.CornerRadius = new CornerRadius(8);
        _root.Background = new SolidColorBrush(Color.FromRgb(31, 41, 55));
        _root.BorderBrush = new SolidColorBrush(Color.FromRgb(107, 114, 128));
        _root.BorderThickness = new Thickness(1);
        _root.Padding = new Thickness(14, 0, 14, 0);
        _root.Child = _statusText;

        _statusText.Text = AppText.StatusPlaceholder;
        _statusText.Foreground = Brushes.White;
        _statusText.FontSize = 16;
        _statusText.FontWeight = FontWeights.SemiBold;
        _statusText.VerticalAlignment = VerticalAlignment.Center;
        _statusText.HorizontalAlignment = HorizontalAlignment.Center;
        _statusText.TextTrimming = TextTrimming.CharacterEllipsis;

        Content = _root;
        MouseLeftButtonDown += OnMouseLeftButtonDown;
        MouseMove += OnMouseMove;
        MouseLeftButtonUp += OnMouseLeftButtonUp;
        MouseRightButtonUp += (_, _) => MenuRequested?.Invoke(this, EventArgs.Empty);
        Loaded += (_, _) => Reposition();
    }

    public void SetStatus(string text, int? remainingPercent)
    {
        _statusText.Text = text;
        var color = ColorForRemaining(remainingPercent);
        _root.Background = new SolidColorBrush(color.Background);
        _root.BorderBrush = new SolidColorBrush(color.Border);
        Reposition();
    }

    public void Reposition()
    {
        if (_hasCustomPosition || TryApplySavedPosition())
        {
            EnsureVisible();
            return;
        }

        var workArea = SystemParameters.WorkArea;
        Left = workArea.Right - Width - 10;
        Top = workArea.Bottom - Height - 8;
    }

    private void OnMouseLeftButtonDown(object sender, MouseButtonEventArgs e)
    {
        _mouseDownPoint = e.GetPosition(this);
        _isDragging = false;
        _ignoreNextClick = false;
    }

    private void OnMouseMove(object sender, MouseEventArgs e)
    {
        if (e.LeftButton != MouseButtonState.Pressed)
        {
            return;
        }

        var current = e.GetPosition(this);
        var movedEnough =
            Math.Abs(current.X - _mouseDownPoint.X) >= SystemParameters.MinimumHorizontalDragDistance ||
            Math.Abs(current.Y - _mouseDownPoint.Y) >= SystemParameters.MinimumVerticalDragDistance;

        if (!movedEnough)
        {
            return;
        }

        _isDragging = true;
        _ignoreNextClick = true;

        try
        {
            DragMove();
            _hasCustomPosition = true;
            EnsureVisible();
            SavePosition();
        }
        catch (InvalidOperationException)
        {
        }
    }

    private void OnMouseLeftButtonUp(object sender, MouseButtonEventArgs e)
    {
        if (_isDragging || _ignoreNextClick)
        {
            _isDragging = false;
            _ignoreNextClick = false;
            return;
        }

        _isDragging = false;
        _ignoreNextClick = false;
    }

    private bool TryApplySavedPosition()
    {
        try
        {
            if (!File.Exists(PositionPath))
            {
                return false;
            }

            var parts = File.ReadAllText(PositionPath)
                .Split(',', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries);
            if (parts.Length != 2 ||
                !double.TryParse(parts[0], NumberStyles.Float, CultureInfo.InvariantCulture, out var left) ||
                !double.TryParse(parts[1], NumberStyles.Float, CultureInfo.InvariantCulture, out var top))
            {
                return false;
            }

            if (!IsOnAnyScreen(left, top))
            {
                return false;
            }

            Left = left;
            Top = top;
            _hasCustomPosition = true;
            return true;
        }
        catch
        {
            return false;
        }
    }

    private void SavePosition()
    {
        try
        {
            Directory.CreateDirectory(Path.GetDirectoryName(PositionPath)!);
            var value = string.Create(
                CultureInfo.InvariantCulture,
                $"{Left:0.###},{Top:0.###}");
            File.WriteAllText(PositionPath, value);
        }
        catch
        {
        }
    }

    private void EnsureVisible()
    {
        if (IsOnAnyScreen(Left, Top))
        {
            return;
        }

        _hasCustomPosition = false;
        var workArea = SystemParameters.WorkArea;
        Left = workArea.Right - Width - 10;
        Top = workArea.Bottom - Height - 8;
        SavePosition();
    }

    private bool IsOnAnyScreen(double left, double top)
    {
        var bounds = new System.Drawing.Rectangle(
            (int)Math.Round(left),
            (int)Math.Round(top),
            (int)Math.Round(Width),
            (int)Math.Round(Height));

        foreach (var screen in Forms.Screen.AllScreens)
        {
            var intersection = System.Drawing.Rectangle.Intersect(bounds, screen.WorkingArea);
            if (intersection.Width >= 20 && intersection.Height >= 20)
            {
                return true;
            }
        }

        return false;
    }

    private static (Color Background, Color Border) ColorForRemaining(int? remainingPercent)
    {
        if (remainingPercent is null)
        {
            return (Color.FromRgb(31, 41, 55), Color.FromRgb(107, 114, 128));
        }

        if (remainingPercent > 50)
        {
            return (Color.FromRgb(22, 101, 52), Color.FromRgb(34, 197, 94));
        }

        if (remainingPercent > 20)
        {
            return (Color.FromRgb(146, 64, 14), Color.FromRgb(245, 158, 11));
        }

        return (Color.FromRgb(153, 27, 27), Color.FromRgb(248, 113, 113));
    }
}
