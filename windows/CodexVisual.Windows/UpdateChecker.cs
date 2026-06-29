using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Net.Http;
using System.Reflection;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading.Tasks;
using System.Windows;

namespace CodexVisual.Windows;

internal static class UpdateChecker
{
    private static readonly Uri ReleasesApi = new("https://api.github.com/repos/orangeshushu/CodexVisual/releases?per_page=30");
    private static readonly Uri ReleasesPage = new("https://github.com/orangeshushu/CodexVisual/releases/latest");

    public static async Task CheckAsync(Window owner)
    {
        try
        {
            using var client = new HttpClient();
            client.DefaultRequestHeaders.UserAgent.ParseAdd("CodexVisual.Windows");
            client.DefaultRequestHeaders.Accept.ParseAdd("application/vnd.github+json");

            using var stream = await client.GetStreamAsync(ReleasesApi);
            var releases = await JsonSerializer.DeserializeAsync<GitHubRelease[]>(stream) ?? [];
            var update = releases
                .Select(CreateWindowsUpdateCandidate)
                .Where(candidate => candidate is not null)
                .Select(candidate => candidate!)
                .OrderByDescending(candidate => NormalizeVersion(candidate.Version), VersionComparer.Instance)
                .FirstOrDefault();

            var currentVersion = Assembly.GetExecutingAssembly().GetName().Version?.ToString(3) ?? "0";
            if (update is null || CompareVersions(update.Version, currentVersion) <= 0)
            {
                MessageBox.Show(owner, AppText.NoUpdateBody(currentVersion), AppText.NoUpdateTitle, MessageBoxButton.OK, MessageBoxImage.Information);
                return;
            }

            var result = MessageBox.Show(owner, AppText.WindowsUpdateAvailableBody(update.Version), AppText.UpdateAvailableTitle, MessageBoxButton.OKCancel, MessageBoxImage.Information);
            if (result == MessageBoxResult.OK)
            {
                OpenUrl(string.IsNullOrWhiteSpace(update.DownloadUrl) ? update.ReleaseUrl : update.DownloadUrl);
            }
        }
        catch (Exception ex)
        {
            MessageBox.Show(owner, ex.Message, AppText.UpdateCheckFailed, MessageBoxButton.OK, MessageBoxImage.Warning);
        }
    }

    private static int CompareVersions(string left, string right)
    {
        if (Version.TryParse(NormalizeVersion(left), out var leftVersion) && Version.TryParse(NormalizeVersion(right), out var rightVersion))
        {
            return leftVersion.CompareTo(rightVersion);
        }

        return string.Compare(left, right, StringComparison.OrdinalIgnoreCase);
    }

    private static WindowsUpdateCandidate? CreateWindowsUpdateCandidate(GitHubRelease release)
    {
        var asset = release.Assets
            .Where(IsWindowsAsset)
            .OrderByDescending(WindowsAssetPriority)
            .FirstOrDefault();

        if (asset is null)
        {
            return null;
        }

        var version = NormalizeVersion(release.TagName);
        if (string.IsNullOrWhiteSpace(version))
        {
            return null;
        }

        return new WindowsUpdateCandidate(
            version,
            asset.BrowserDownloadUrl,
            string.IsNullOrWhiteSpace(release.HtmlUrl) ? ReleasesPage.ToString() : release.HtmlUrl);
    }

    private static bool IsWindowsAsset(GitHubAsset asset)
    {
        var value = $"{asset.Name} {asset.BrowserDownloadUrl}".ToLowerInvariant();
        if (value.Contains("macos") || value.Contains("darwin") || value.Contains(".dmg") || value.Contains(".pkg"))
        {
            return false;
        }

        return value.Contains("windows") ||
               value.Contains("win-") ||
               value.Contains("win_") ||
               value.Contains("win64") ||
               value.Contains("x64.exe") ||
               value.EndsWith(".msi", StringComparison.OrdinalIgnoreCase) ||
               value.EndsWith(".msix", StringComparison.OrdinalIgnoreCase) ||
               value.EndsWith(".exe", StringComparison.OrdinalIgnoreCase);
    }

    private static int WindowsAssetPriority(GitHubAsset asset)
    {
        var name = asset.Name.ToLowerInvariant();
        if (name.Contains("setup") || name.Contains("installer"))
        {
            return 4;
        }

        if (name.EndsWith(".msi", StringComparison.OrdinalIgnoreCase) || name.EndsWith(".msix", StringComparison.OrdinalIgnoreCase))
        {
            return 3;
        }

        if (name.EndsWith(".exe", StringComparison.OrdinalIgnoreCase))
        {
            return 2;
        }

        return 1;
    }

    private static string NormalizeVersion(string value)
    {
        var trimmed = value.Trim().TrimStart('v', 'V');
        var start = trimmed.TakeWhile(character => char.IsDigit(character) || character == '.').ToArray();
        return start.Length == 0 ? trimmed : new string(start).Trim('.');
    }

    private static void OpenUrl(string url)
    {
        Process.Start(new ProcessStartInfo
        {
            FileName = url,
            UseShellExecute = true
        });
    }

    private sealed class GitHubRelease
    {
        [JsonPropertyName("tag_name")]
        public string TagName { get; set; } = "";

        [JsonPropertyName("html_url")]
        public string HtmlUrl { get; set; } = "";

        [JsonPropertyName("assets")]
        public GitHubAsset[] Assets { get; set; } = [];
    }

    private sealed class GitHubAsset
    {
        [JsonPropertyName("name")]
        public string Name { get; set; } = "";

        [JsonPropertyName("browser_download_url")]
        public string BrowserDownloadUrl { get; set; } = "";
    }

    private sealed record WindowsUpdateCandidate(string Version, string DownloadUrl, string ReleaseUrl);

    private sealed class VersionComparer : IComparer<string>
    {
        public static readonly VersionComparer Instance = new();

        public int Compare(string? x, string? y) => CompareVersions(x ?? "0", y ?? "0");
    }
}
