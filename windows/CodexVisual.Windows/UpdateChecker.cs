using System;
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
    private static readonly Uri LatestReleaseApi = new("https://api.github.com/repos/orangeshushu/CodexVisual/releases/latest");
    private static readonly Uri ReleasesPage = new("https://github.com/orangeshushu/CodexVisual/releases/latest");

    public static async Task CheckAsync(Window owner)
    {
        try
        {
            using var client = new HttpClient();
            client.DefaultRequestHeaders.UserAgent.ParseAdd("CodexVisual.Windows");
            client.DefaultRequestHeaders.Accept.ParseAdd("application/vnd.github+json");

            using var stream = await client.GetStreamAsync(LatestReleaseApi);
            var release = await JsonSerializer.DeserializeAsync<GitHubRelease>(stream);
            var remoteVersion = release?.TagName?.TrimStart('v', 'V') ?? "0";
            var currentVersion = Assembly.GetExecutingAssembly().GetName().Version?.ToString(3) ?? "0";

            if (CompareVersions(remoteVersion, currentVersion) <= 0)
            {
                MessageBox.Show(owner, AppText.NoUpdateBody(currentVersion), AppText.NoUpdateTitle, MessageBoxButton.OK, MessageBoxImage.Information);
                return;
            }

            var result = MessageBox.Show(owner, AppText.UpdateAvailableBody(remoteVersion), AppText.UpdateAvailableTitle, MessageBoxButton.OKCancel, MessageBoxImage.Information);
            if (result == MessageBoxResult.OK)
            {
                OpenUrl(release?.HtmlUrl ?? ReleasesPage.ToString());
            }
        }
        catch (Exception ex)
        {
            MessageBox.Show(owner, ex.Message, AppText.UpdateCheckFailed, MessageBoxButton.OK, MessageBoxImage.Warning);
        }
    }

    private static int CompareVersions(string left, string right)
    {
        if (Version.TryParse(left, out var leftVersion) && Version.TryParse(right, out var rightVersion))
        {
            return leftVersion.CompareTo(rightVersion);
        }

        return string.Compare(left, right, StringComparison.OrdinalIgnoreCase);
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
}
