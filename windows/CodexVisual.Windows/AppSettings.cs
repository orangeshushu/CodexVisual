using System;
using System.Collections.Generic;
using System.IO;

namespace CodexVisual.Windows;

internal sealed class AppSettings
{
    public const string LanguageSystem = "system";
    public const string LanguageChinese = "zh";
    public const string LanguageEnglish = "en";

    private static readonly string SettingsPath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
        "CodexVisual",
        "windows-settings.txt");

    public static AppSettings Current { get; } = Load();

    public string Language { get; set; } = LanguageSystem;

    public void Save()
    {
        Directory.CreateDirectory(Path.GetDirectoryName(SettingsPath)!);
        File.WriteAllLines(SettingsPath, new[]
        {
            $"language={Language}"
        });
    }

    private static AppSettings Load()
    {
        var settings = new AppSettings();
        if (!File.Exists(SettingsPath))
        {
            return settings;
        }

        try
        {
            var values = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            foreach (var line in File.ReadAllLines(SettingsPath))
            {
                var separator = line.IndexOf('=');
                if (separator <= 0)
                {
                    continue;
                }

                values[line[..separator].Trim()] = line[(separator + 1)..].Trim();
            }

            if (values.TryGetValue("language", out var language) && IsValidLanguage(language))
            {
                settings.Language = language;
            }
        }
        catch
        {
        }

        return settings;
    }

    private static bool IsValidLanguage(string language) =>
        language is LanguageSystem or LanguageChinese or LanguageEnglish;
}
