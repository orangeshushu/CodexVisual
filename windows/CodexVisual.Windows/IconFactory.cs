using System;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Runtime.InteropServices;

namespace CodexVisual.Windows;

internal static class IconFactory
{
    public static Icon CreateTrayIcon()
    {
        var appIcon = TryLoadApplicationIcon();
        if (appIcon is not null)
        {
            return appIcon;
        }

        using var bitmap = new Bitmap(32, 32);
        using var graphics = Graphics.FromImage(bitmap);
        graphics.SmoothingMode = SmoothingMode.AntiAlias;
        graphics.Clear(Color.Transparent);

        using var background = new SolidBrush(Color.FromArgb(37, 99, 235));
        graphics.FillEllipse(background, 2, 2, 28, 28);

        using var font = new Font("Segoe UI", 11, FontStyle.Bold, GraphicsUnit.Pixel);
        using var textBrush = new SolidBrush(Color.White);
        var text = "C";
        var size = graphics.MeasureString(text, font);
        graphics.DrawString(text, font, textBrush, (32 - size.Width) / 2, (32 - size.Height) / 2 - 1);

        var handle = bitmap.GetHicon();
        try
        {
            return (Icon)Icon.FromHandle(handle).Clone();
        }
        finally
        {
            DestroyIcon(handle);
        }
    }

    private static Icon? TryLoadApplicationIcon()
    {
        try
        {
            var executablePath = Environment.ProcessPath
                ?? Process.GetCurrentProcess().MainModule?.FileName;
            if (string.IsNullOrWhiteSpace(executablePath))
            {
                return null;
            }

            using var icon = Icon.ExtractAssociatedIcon(executablePath);
            return icon is null ? null : (Icon)icon.Clone();
        }
        catch
        {
            return null;
        }
    }

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool DestroyIcon(IntPtr hIcon);
}
