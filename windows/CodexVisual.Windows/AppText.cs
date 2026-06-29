using System;
using System.Globalization;

namespace CodexVisual.Windows;

internal static class AppText
{
    private static readonly CultureInfo SystemCulture = CultureInfo.CurrentCulture;
    private static readonly CultureInfo SystemUICulture = CultureInfo.CurrentUICulture;

    public static bool UsesChinese => EffectiveCulture.Name.StartsWith("zh", StringComparison.OrdinalIgnoreCase);

    public static string Text(string chinese, string english) => UsesChinese ? chinese : english;

    public static void ApplyLanguage()
    {
        var language = AppSettings.Current.Language;
        if (language == AppSettings.LanguageSystem)
        {
            CultureInfo.CurrentCulture = SystemCulture;
            CultureInfo.CurrentUICulture = SystemUICulture;
            return;
        }

        var culture = language == AppSettings.LanguageChinese
            ? CultureInfo.GetCultureInfo("zh-CN")
            : CultureInfo.GetCultureInfo("en-US");

        CultureInfo.CurrentCulture = culture;
        CultureInfo.CurrentUICulture = culture;
    }

    public static string StatusPlaceholder => "Codex -- / --%";
    public static string AppTitle => Text("Codex 额度", "Codex Quota");
    public static string TrayToolTip => Text("Codex 额度", "Codex quota");
    public static string Plan(string value) => Text($"计划: {value}", $"Plan: {value}");
    public static string Unknown => Text("未知", "Unknown");
    public static string FiveHourQuota => Text("5 小时额度", "5-hour quota");
    public static string SevenDayQuota => Text("7 天额度", "7-day quota");
    public static string Remaining => Text("剩余", "Remaining");
    public static string Used => Text("已用", "Used");
    public static string ResetTime => Text("重置时间", "Reset time");
    public static string DataSource => Text("数据来源", "Data source");
    public static string LastRead => Text("最后读取时间", "Last read");
    public static string RefreshNow => Text("立即刷新", "Refresh Now");
    public static string CheckForUpdates => Text("检查更新", "Check for Updates");
    public static string Exit => Text("退出", "Exit");
    public static string OpenWindow => Text("打开额度窗口", "Open Quota Window");
    public static string Language => Text("语言", "Language");
    public static string SystemLanguage => Text("跟随系统", "System");
    public static string Chinese => Text("中文", "Chinese");
    public static string English => Text("英文", "English");
    public static string StartAtLogin => Text("开机自动启动", "Start at Login");
    public static string SettingsFailed => Text("设置失败", "Settings Failed");
    public static string SmartRefresh => Text("智能刷新", "Smart refresh");
    public static string CodexSessions => Text("Codex 会话", "Codex sessions");
    public static string CodexLogs => Text("Codex 日志", "Codex logs");
    public static string CheckingUpdates => Text("正在检查更新...", "Checking for updates...");
    public static string NoUpdateTitle => Text("已是最新版本", "You're up to date");
    public static string NoUpdateBody(string version) => Text($"当前版本 {version} 已是最新版本。", $"Version {version} is already the latest version.");
    public static string UpdateAvailableTitle => Text("发现新版本", "Update Available");
    public static string UpdateAvailableBody(string version) => Text($"发现 CodexVisual {version}。是否打开 GitHub Release 页面下载？", $"CodexVisual {version} is available. Open the GitHub Releases page to download it?");
    public static string WindowsUpdateAvailableBody(string version) => Text($"发现 CodexVisual Windows {version}。是否打开下载？", $"CodexVisual Windows {version} is available. Open the download?");
    public static string UpdateCheckFailed => Text("检查更新失败", "Update Check Failed");
    public static string OpenReleasePage => Text("打开下载页面", "Open Download Page");
    public static string Cancel => Text("取消", "Cancel");

    public static string NoQuotaYet => Text(
        "请打开 Codex，用当前账号发送一条消息，然后点击立即刷新。",
        "Open Codex, send one message with the current account, then click Refresh Now.");

    public static string MissingEvent => Text(
        "没有读取到当前有效的 codex.rate_limits 事件。请打开 Codex，用当前账号发送一条消息，然后点击立即刷新。",
        "No current codex.rate_limits event was found. Open Codex, send one message with the current account, then click Refresh Now.");

    public static string MissingExpiredEvent(DateTimeOffset resetTime) => Text(
        $"最后一次 Codex 额度事件已经过期（最后重置时间: {FormatDateTime(resetTime)}）。请打开 Codex，用当前账号发送一条消息，然后点击立即刷新。",
        $"The latest Codex quota event has expired (last reset: {FormatDateTime(resetTime)}). Open Codex, send one message with the current account, then click Refresh Now.");

    public static string MissingDatabase(string pathList) => Text(
        $"没有找到 Codex 日志数据库: {pathList}",
        $"Codex log database not found: {pathList}");

    public static string SqliteFailed(string message) => Text(
        $"读取 SQLite 失败: {message}",
        $"Failed to read SQLite: {message}");

    public static string FormatDateTime(DateTimeOffset value) =>
        value.LocalDateTime.ToString(UsesChinese ? "yyyy年M月d日 HH:mm:ss" : "yyyy-MM-dd HH:mm:ss", CultureInfo.CurrentCulture);

    private static CultureInfo EffectiveCulture
    {
        get
        {
            return AppSettings.Current.Language switch
            {
                AppSettings.LanguageChinese => CultureInfo.GetCultureInfo("zh-CN"),
                AppSettings.LanguageEnglish => CultureInfo.GetCultureInfo("en-US"),
                _ => SystemUICulture
            };
        }
    }
}
