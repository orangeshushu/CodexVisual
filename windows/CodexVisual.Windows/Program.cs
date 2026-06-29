using System;
using System.Linq;
using System.Threading;
using System.Windows;

namespace CodexVisual.Windows;

internal static class Program
{
    [STAThread]
    private static void Main(string[] args)
    {
        using var mutex = new Mutex(true, "orangeshushu.CodexVisual.Windows", out var created);
        if (!created)
        {
            return;
        }

        if (args.Contains("--diagnostics", StringComparer.OrdinalIgnoreCase))
        {
            Console.WriteLine(new QuotaReader().Diagnostics());
            return;
        }

        AppText.ApplyLanguage();

        var app = new Application
        {
            ShutdownMode = ShutdownMode.OnExplicitShutdown
        };

        using var controller = new TrayController(app, new QuotaReader());
        controller.Start();
        app.Run();
    }
}
