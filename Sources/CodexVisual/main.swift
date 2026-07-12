import AppKit
import Foundation

enum LanguageMode: String, CaseIterable {
    case system
    case english
    case chinese

    static let defaultsKey = "languageMode"

    static var current: LanguageMode {
        get {
            if let override = ProcessInfo.processInfo.environment["CODEX_VISUAL_LANGUAGE"] {
                return override.lowercased().hasPrefix("zh") ? .chinese : .english
            }

            if let rawValue = UserDefaults.standard.string(forKey: defaultsKey),
               let mode = LanguageMode(rawValue: rawValue) {
                return mode
            }

            return .system
        }
        set {
            if newValue == .system {
                UserDefaults.standard.removeObject(forKey: defaultsKey)
            } else {
                UserDefaults.standard.set(newValue.rawValue, forKey: defaultsKey)
            }
        }
    }
}

enum RefreshMode: String, CaseIterable {
    case smart
    case everyFiveSeconds
    case everyFifteenSeconds
    case everySixtySeconds
    case everyFiveMinutes
    case manual

    static let defaultsKey = "refreshMode"

    static var current: RefreshMode {
        get {
            if let rawValue = UserDefaults.standard.string(forKey: defaultsKey),
               let mode = RefreshMode(rawValue: rawValue) {
                return mode
            }

            return .smart
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: defaultsKey)
        }
    }

    var baseInterval: TimeInterval? {
        switch self {
        case .smart:
            return 15
        case .everyFiveSeconds:
            return 5
        case .everyFifteenSeconds:
            return 15
        case .everySixtySeconds:
            return 60
        case .everyFiveMinutes:
            return 300
        case .manual:
            return nil
        }
    }
}

enum MenuBarDisplayMode: String, CaseIterable {
    case bars
    case numbers

    static let defaultsKey = "menuBarDisplayMode"

    static var current: MenuBarDisplayMode {
        get {
            if let rawValue = UserDefaults.standard.string(forKey: defaultsKey),
               let mode = MenuBarDisplayMode(rawValue: rawValue) {
                return mode
            }

            return .bars
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: defaultsKey)
        }
    }
}

enum MenuBarTextGroup: String, CaseIterable {
    case bar
    case label
    case percent
    case reset

    var defaultsKey: String {
        "menuBarTextColor.\(rawValue)"
    }

    var defaultColor: MenuBarTextColor {
        switch self {
        case .label, .reset:
            return .white
        case .bar, .percent:
            return .quota
        }
    }

    var currentColor: MenuBarTextColor {
        get {
            if let rawValue = UserDefaults.standard.string(forKey: defaultsKey),
               let color = MenuBarTextColor(rawValue: rawValue) {
                return color
            }

            return defaultColor
        }
        nonmutating set {
            if newValue == defaultColor {
                UserDefaults.standard.removeObject(forKey: defaultsKey)
            } else {
                UserDefaults.standard.set(newValue.rawValue, forKey: defaultsKey)
            }
        }
    }
}

enum MenuBarTextColor: String, CaseIterable {
    case quota
    case white
    case blue
    case green
    case yellow
    case red
    case gray

    func resolved(for remaining: Int) -> NSColor {
        switch self {
        case .quota:
            return QuotaColor.statusText(for: remaining)
        case .white:
            return NSColor.white.withAlphaComponent(0.96)
        case .blue:
            return NSColor(calibratedRed: 0.42, green: 0.72, blue: 1.00, alpha: 1)
        case .green:
            return NSColor(calibratedRed: 0.40, green: 0.95, blue: 0.62, alpha: 1)
        case .yellow:
            return NSColor(calibratedRed: 1.00, green: 0.78, blue: 0.24, alpha: 1)
        case .red:
            return NSColor(calibratedRed: 1.00, green: 0.42, blue: 0.38, alpha: 1)
        case .gray:
            return NSColor.white.withAlphaComponent(0.68)
        }
    }

    func resolvedForBar(for remaining: Int) -> NSColor {
        switch self {
        case .quota:
            return QuotaColor.fill(for: remaining)
        default:
            return resolved(for: remaining)
        }
    }

    var previewColors: [NSColor] {
        switch self {
        case .quota:
            return [
                QuotaColor.fill(for: 90),
                QuotaColor.fill(for: 70),
                QuotaColor.fill(for: 35),
                QuotaColor.fill(for: 10)
            ]
        default:
            return [resolved(for: 100)]
        }
    }
}

enum AppStrings {
    static var usesChinese: Bool {
        let language: String
        switch LanguageMode.current {
        case .system:
            language = preferredAppleLanguage ?? Locale.preferredLanguages.first ?? "en"
        case .english:
            language = "en"
        case .chinese:
            language = "zh"
        }
        return language.lowercased().hasPrefix("zh")
    }

    private static var preferredAppleLanguage: String? {
        if let languages = UserDefaults.standard.array(forKey: "AppleLanguages") as? [String] {
            return languages.first
        }

        if let languages = UserDefaults.standard.stringArray(forKey: "AppleLanguages") {
            return languages.first
        }

        return UserDefaults.standard.string(forKey: "AppleLanguages")
    }

    static func text(_ chinese: String, _ english: String) -> String {
        usesChinese ? chinese : english
    }

    static var dateLocale: Locale {
        Locale(identifier: usesChinese ? "zh_Hans_US" : "en_US_POSIX")
    }

    static var dateFormat: String {
        usesChinese ? "M月d日 E HH:mm" : "EEE MMM d HH:mm"
    }

    static var shortTimeFormat: String {
        "HH:mm:ss"
    }

    static let statusTitlePlaceholder = "Codex --%"
    static var statusToolTip: String { text("Codex 额度", "Codex quota") }
    static var displayOrder: String { text("显示: 每周额度", "Display: weekly quota") }
    static var refreshNow: String { text("立即刷新", "Refresh Now") }
    static var quit: String { text("退出", "Quit") }
    static var openDashboard: String { text("打开控制窗口", "Open Control Window") }
    static var uninstall: String { text("卸载 CodexVisual", "Uninstall CodexVisual") }
    static var uninstallTitle: String { text("卸载 CodexVisual?", "Uninstall CodexVisual?") }
    static var uninstallMessage: String {
        text("这会退出应用，并删除本机安装的 CodexVisual.app 与本地缓存。Codex 登录信息和 Codex 日志不会被删除。",
             "This will quit the app and remove the installed CodexVisual.app plus local cache. Codex login data and Codex logs will not be removed.")
    }
    static var uninstallConfirm: String { text("卸载", "Uninstall") }
    static var cancel: String { text("取消", "Cancel") }
    static var uninstallDone: String { text("CodexVisual 已卸载", "CodexVisual has been uninstalled") }
    static var refreshFrequency: String { text("刷新频率", "Refresh Frequency") }
    static var refreshSmart: String { text("智能刷新", "Smart") }
    static var refreshEvery5Seconds: String { text("每 5 秒", "Every 5 seconds") }
    static var refreshEvery15Seconds: String { text("每 15 秒", "Every 15 seconds") }
    static var refreshEvery60Seconds: String { text("每 60 秒", "Every 60 seconds") }
    static var refreshEvery5Minutes: String { text("每 5 分钟", "Every 5 minutes") }
    static var refreshManual: String { text("手动", "Manual") }
    static var menuBarDisplay: String { text("菜单栏显示方式", "Menu Bar Display") }
    static var menuBarDisplayBars: String { text("进度条", "Progress Bar") }
    static var menuBarDisplayNumbers: String { text("数字", "Numbers") }
    static var menuBarTextColor: String { text("菜单栏颜色", "Menu Bar Colors") }
    static var menuBarTextBar: String { text("进度条", "Progress Bar") }
    static var menuBarTextLabel: String { text("时间标签", "Time Label") }
    static var menuBarTextPercent: String { text("百分比", "Percentage") }
    static var menuBarTextReset: String { text("刷新时间", "Reset Time") }
    static var colorQuota: String { text("跟随额度", "By Quota") }
    static var colorWhite: String { text("白色", "White") }
    static var colorBlue: String { text("蓝色", "Blue") }
    static var colorGreen: String { text("绿色", "Green") }
    static var colorYellow: String { text("黄色", "Yellow") }
    static var colorRed: String { text("红色", "Red") }
    static var colorGray: String { text("灰色", "Gray") }
    static var checkForUpdates: String { text("检查更新", "Check for Updates") }
    static var checkingUpdates: String { text("正在检查更新...", "Checking for updates...") }
    static var updateAvailableTitle: String { text("发现新版本", "Update Available") }
    static func updateAvailableMessage(_ version: String) -> String {
        text("发现 CodexVisual \(version)。是否自动下载并安装？",
             "CodexVisual \(version) is available. Download and install it automatically?")
    }
    static var updateNow: String { text("立即更新", "Update Now") }
    static var noUpdateTitle: String { text("已是最新版本", "You're up to date") }
    static func noUpdateMessage(_ version: String) -> String {
        text("当前版本 \(version) 已是最新版本。", "Version \(version) is already the latest version.")
    }
    static var updateStartedTitle: String { text("开始更新", "Update Started") }
    static var updateStartedMessage: String {
        text("CodexVisual 会自动下载新版、替换应用并重新打开。",
             "CodexVisual will download the new version, replace the app, and reopen automatically.")
    }
    static var updateFailedTitle: String { text("检查更新失败", "Update Check Failed") }
    static var language: String { text("语言", "Language") }
    static var languageSystem: String { text("跟随系统", "System") }
    static var languageEnglish: String { "English" }
    static var languageChinese: String { "中文" }
    static var unknown: String { text("未知", "Unknown") }
    static var codexSessions: String { text("Codex 会话", "Codex sessions") }
    static var codexLogs: String { text("Codex 日志", "Codex logs") }
    static var localCache: String { text("本地缓存", "local cache") }
    static var migratedCache: String { text("旧版缓存", "legacy cache") }
    static var quotaOverview: String { text("Codex 额度", "Codex Quota") }
    static var controlWindowTitle: String { text("CodexVisual 控制窗口", "CodexVisual Control Window") }
    static var noQuotaYet: String { text("还没有读取到 Codex 额度。请打开 Codex 并发送一条消息，然后点击刷新。", "No Codex quota has been read yet. Open Codex, send one message, then click Refresh.") }
    static var weeklyQuota: String { text("每周", "Weekly") }
    static var remaining: String { text("剩余", "remaining") }

    static func missingDatabase(_ path: String) -> String {
        text("未找到 Codex 日志数据库: \(path)", "Codex log database not found: \(path)")
    }

    static func sqliteFailed(_ message: String) -> String {
        text("读取 SQLite 失败: \(message)", "Failed to read SQLite: \(message)")
    }

    static var missingEvent: String {
        text("还没有读到当前有效的 codex.rate_limits 事件。请在当前登录的 Codex 账号中发送一条消息后再刷新。",
             "No current codex.rate_limits event has been found yet. Send one message from the currently signed-in Codex account, then refresh.")
    }

    static var invalidLogRow: String {
        text("日志行格式无法解析", "Could not parse the log row")
    }

    static var invalidJSON: String {
        text("额度事件 JSON 无法解析", "Could not parse the quota event JSON")
    }

    static func cannotRunSQLite(_ message: String) -> String {
        text("无法运行 sqlite3: \(message)", "Could not run sqlite3: \(message)")
    }

    static func quotaToolTip(weekly: Int) -> String {
        text("每周剩余: \(weekly)%", "Weekly remaining: \(weekly)%")
    }

    static func plan(_ value: String) -> String {
        text("计划: \(value)", "Plan: \(value)")
    }


    static func dataSource(source: String, time: String) -> String {
        text("数据来源: \(source), \(time)", "Data source: \(source), \(time)")
    }

    static func lastRead(_ value: String) -> String {
        text("最后读取: \(value)", "Last read: \(value)")
    }

    static func usedCompact(_ value: Int) -> String {
        text("已用 \(value)%", "Used \(value)%")
    }

    static func resetCompact(_ value: String) -> String {
        text("重置 \(value)", "Reset \(value)")
    }

    static var resetPending: String {
        text("等待 Codex 更新", "waiting for Codex update")
    }

    static func sourceCompact(source: String, readTime: String) -> String {
        text("来源: \(source) · 读取: \(readTime)", "Source: \(source) · Read: \(readTime)")
    }
}

enum SnapshotSource: String {
    case codexSessions
    case codexLogs
    case localCache
    case migratedCache

    var title: String {
        switch self {
        case .codexSessions:
            return AppStrings.codexSessions
        case .codexLogs:
            return AppStrings.codexLogs
        case .localCache:
            return AppStrings.localCache
        case .migratedCache:
            return AppStrings.migratedCache
        }
    }
}

struct RateLimitEvent: Codable {
    let type: String
    let planType: String?
    let rateLimits: RateLimits

    enum CodingKeys: String, CodingKey {
        case type
        case planType = "plan_type"
        case rateLimits = "rate_limits"
    }
}

struct RateLimits: Codable {
    let allowed: Bool
    let limitReached: Bool
    let primary: QuotaWindow?
    let secondary: QuotaWindow?

    var weekly: QuotaWindow? {
        [primary, secondary]
            .compactMap { $0 }
            .max { $0.windowMinutes < $1.windowMinutes }
    }

    enum CodingKeys: String, CodingKey {
        case allowed
        case limitReached = "limit_reached"
        case primary
        case secondary
    }
}

struct QuotaWindow: Codable {
    let usedPercent: Int
    let windowMinutes: Int
    let resetAfterSeconds: Int?
    let resetAt: TimeInterval

    enum CodingKeys: String, CodingKey {
        case usedPercent = "used_percent"
        case windowMinutes = "window_minutes"
        case resetAfterSeconds = "reset_after_seconds"
        case resetAt = "reset_at"
    }

    var remainingPercent: Int {
        min(100, max(0, 100 - effectiveUsedPercent))
    }

    var effectiveUsedPercent: Int {
        resetDate <= Date() ? 0 : usedPercent
    }

    var resetDate: Date {
        Date(timeIntervalSince1970: resetAt)
    }
}

struct QuotaSnapshot {
    let event: RateLimitEvent
    let logDate: Date
    let readDate: Date
    let source: SnapshotSource
}

enum QuotaReadError: Error, LocalizedError {
    case missingDatabase(String)
    case sqliteFailed(String)
    case missingEvent
    case invalidLogRow
    case invalidJSON
    case cannotRunSQLite(String)

    var errorDescription: String? {
        switch self {
        case .missingDatabase(let path):
            return AppStrings.missingDatabase(path)
        case .sqliteFailed(let message):
            return AppStrings.sqliteFailed(message)
        case .missingEvent:
            return AppStrings.missingEvent
        case .invalidLogRow:
            return AppStrings.invalidLogRow
        case .invalidJSON:
            return AppStrings.invalidJSON
        case .cannotRunSQLite(let message):
            return AppStrings.cannotRunSQLite(message)
        }
    }
}

final class QuotaReader {
    private let sqlitePath = "/usr/bin/sqlite3"
    private let databasePaths: [String]
    private let sessionsDirectory: URL

    init(databasePaths: [String]? = nil) {
        let home = NSHomeDirectory()
        if let override = ProcessInfo.processInfo.environment["CODEX_VISUAL_SESSIONS_DIR"],
           !override.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.sessionsDirectory = URL(fileURLWithPath: override)
        } else {
            self.sessionsDirectory = URL(fileURLWithPath: home + "/.codex/sessions")
        }

        if let override = ProcessInfo.processInfo.environment["CODEX_VISUAL_LOG_DB"],
           !override.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.databasePaths = [override]
        } else if let databasePaths {
            self.databasePaths = databasePaths
        } else {
            self.databasePaths = [
                home + "/.codex/logs_2.sqlite",
                home + "/.codex/sqlite/logs_2.sqlite",
                home + "/.codex/logs.sqlite",
                home + "/.codex/sqlite/logs.sqlite"
            ]
        }
    }

    func readLatest(allowCache: Bool = true) throws -> QuotaSnapshot {
        var existingDatabaseSeen = false
        var sqliteErrors: [String] = []

        for databasePath in databasePaths {
            guard FileManager.default.fileExists(atPath: databasePath) else {
                continue
            }

            existingDatabaseSeen = true

            do {
                if let liveSnapshot = try readFromLogs(databasePath: databasePath) {
                    saveCache(snapshot: liveSnapshot)
                    return liveSnapshot
                }
            } catch QuotaReadError.sqliteFailed(let message) {
                sqliteErrors.append("\(databasePath): \(message)")
            } catch {
                throw error
            }
        }

        if let sessionSnapshot = readFromSessions() {
            saveCache(snapshot: sessionSnapshot)
            return sessionSnapshot
        }

        if allowCache, let cachedSnapshot = readCache() {
            return cachedSnapshot
        }

        if !sqliteErrors.isEmpty {
            throw QuotaReadError.sqliteFailed(sqliteErrors.joined(separator: "\n"))
        }

        if !existingDatabaseSeen {
            throw QuotaReadError.missingDatabase(databasePaths.joined(separator: ", "))
        }

        throw QuotaReadError.missingEvent
    }

    private func readFromSessions() -> QuotaSnapshot? {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: sessionsDirectory.path) else {
            return nil
        }

        let resourceKeys: [URLResourceKey] = [.isRegularFileKey, .contentModificationDateKey, .fileSizeKey]
        guard let enumerator = fileManager.enumerator(
            at: sessionsDirectory,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        let cutoff = Date().addingTimeInterval(-14 * 24 * 60 * 60)
        var files: [(url: URL, modified: Date, size: UInt64)] = []

        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "jsonl",
                  let values = try? fileURL.resourceValues(forKeys: Set(resourceKeys)),
                  values.isRegularFile == true else {
                continue
            }

            let modified = values.contentModificationDate ?? .distantPast
            guard modified >= cutoff else {
                continue
            }

            files.append((fileURL, modified, UInt64(values.fileSize ?? 0)))
        }

        let sortedFiles = files.sorted { $0.modified > $1.modified }.prefix(40)
        for file in sortedFiles {
            if let snapshot = readFromSessionFile(url: file.url, size: file.size) {
                return snapshot
            }
        }

        return nil
    }

    private func readFromSessionFile(url: URL, size: UInt64) -> QuotaSnapshot? {
        if isSubagentSessionFile(url: url) {
            return nil
        }

        let maxTailBytes: UInt64 = 4 * 1024 * 1024
        let data: Data

        do {
            let handle = try FileHandle(forReadingFrom: url)
            defer {
                try? handle.close()
            }

            if size > maxTailBytes {
                try handle.seek(toOffset: size - maxTailBytes)
                data = try handle.readToEnd() ?? Data()
            } else {
                data = try handle.readToEnd() ?? Data()
            }
        } catch {
            return nil
        }

        guard var text = String(data: data, encoding: .utf8), !text.isEmpty else {
            return nil
        }

        if size > maxTailBytes, let firstNewline = text.firstIndex(of: "\n") {
            text.removeSubrange(text.startIndex...firstNewline)
        }

        for line in text.split(separator: "\n", omittingEmptySubsequences: true).reversed() {
            guard line.contains("\"rate_limits\""),
                  line.contains("\"token_count\""),
                  let snapshot = decodeSessionRateLimitLine(String(line)) else {
                continue
            }

            if isCurrentRateLimitEvent(snapshot.event), isUsefulRateLimitEvent(snapshot.event) {
                return snapshot
            }
        }

        return nil
    }

    private func isSubagentSessionFile(url: URL) -> Bool {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return false
        }
        defer {
            try? handle.close()
        }

        let headData = (try? handle.read(upToCount: 64 * 1024)) ?? Data()
        guard let headText = String(data: headData, encoding: .utf8),
              let firstLine = headText.split(separator: "\n", omittingEmptySubsequences: true).first,
              let data = String(firstLine).data(using: .utf8),
              let entry = try? JSONDecoder().decode(SessionMetaLogEntry.self, from: data),
              entry.type == "session_meta" else {
            return false
        }

        return entry.payload.threadSource == "subagent" || entry.payload.source?.isSubagent == true
    }

    private func isUsefulRateLimitEvent(_ event: RateLimitEvent) -> Bool {
        let limits = event.rateLimits
        return (limits.weekly?.usedPercent ?? 0) > 0 || limits.limitReached
    }

    private func decodeSessionRateLimitLine(_ line: String) -> QuotaSnapshot? {
        guard let data = line.data(using: .utf8),
              let entry = try? JSONDecoder().decode(SessionLogEntry.self, from: data),
              entry.payload.type == "token_count",
              let sessionRateLimits = entry.payload.rateLimits else {
            return nil
        }

        let primary = quotaWindow(from: sessionRateLimits.primary)
        let secondary = quotaWindow(from: sessionRateLimits.secondary)
        guard primary != nil || secondary != nil else {
            return nil
        }

        let event = RateLimitEvent(
            type: "codex.rate_limits",
            planType: sessionRateLimits.planType,
            rateLimits: RateLimits(
                allowed: true,
                limitReached: sessionRateLimits.rateLimitReachedType != nil,
                primary: primary,
                secondary: secondary
            )
        )

        return QuotaSnapshot(
            event: event,
            logDate: parseSessionTimestamp(entry.timestamp) ?? Date(),
            readDate: Date(),
            source: .codexSessions
        )
    }

    private func quotaWindow(from window: SessionQuotaWindow?) -> QuotaWindow? {
        guard let window else {
            return nil
        }
        let usedPercent = min(100, max(0, Int(ceil(window.usedPercent))))

        return QuotaWindow(
            usedPercent: usedPercent,
            windowMinutes: window.windowMinutes,
            resetAfterSeconds: max(0, Int(window.resetsAt - Date().timeIntervalSince1970)),
            resetAt: window.resetsAt
        )
    }

    private func parseSessionTimestamp(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: value) {
            return date
        }

        return ISO8601DateFormatter().date(from: value)
    }

    private func readFromLogs(databasePath: String) throws -> QuotaSnapshot? {
        guard let schema = try loadLogSchema(databasePath: databasePath) else {
            return nil
        }

        let body = quoteIdentifier(schema.bodyColumn)
        let exactEventClause = """
        (
          \(body) like 'Received message {"type":"codex.rate_limits"%'
          or \(body) like 'Received message {\\\"type\\\":\\\"codex.rate_limits\\\"%'
          or (
            \(body) like '%responses_websocket.stream_request%'
            and (
              \(body) like '%: websocket event: {"type":"codex.rate_limits"%'
              or \(body) like '%: websocket event: {\\\"type\\\":\\\"codex.rate_limits\\\"%'
            )
          )
        )
        and \(body) not like '%exec_command%'
        and \(body) not like '%tool exec_command%'
        and \(body) not like '%*** Begin Patch%'
        and \(body) not like '%Sources/CodexVisual%'
        """
        return try readFromLogs(databasePath: databasePath, schema: schema, whereClause: exactEventClause, limit: 100)
    }

    private func readFromLogs(databasePath: String, schema: LogSchema, whereClause: String, limit: Int) throws -> QuotaSnapshot? {
        let ts = quoteIdentifier(schema.timestampColumn)
        let body = quoteIdentifier(schema.bodyColumn)
        let id = quoteIdentifier(schema.idColumn ?? "rowid")
        let orderColumns = [schema.timestampColumn, schema.timestampNanosColumn, schema.idColumn]
            .compactMap { $0 }
            .map { "\(quoteIdentifier($0)) desc" }
            .joined(separator: ", ")
        let recentLimit = max(limit * 20, 10_000)
        let query = """
        with recent_ids as (
            select \(id)
            from logs
            order by \(orderColumns)
            limit \(recentLimit)
        )
        select
            \(ts),
            substr(
                \(body),
                case when instr(\(body), 'codex.rate_limits') > 128 then instr(\(body), 'codex.rate_limits') - 128 else 1 end,
                100000
            )
        from logs
        where \(id) in recent_ids
          and \(whereClause)
        order by \(orderColumns)
        limit \(limit)
        ;
        """

        let output = try runSQLite(databasePath: databasePath, query: query)
        for line in output.split(separator: "\n", omittingEmptySubsequences: true) {
            let parts = line.split(separator: "\t", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2, let timestamp = TimeInterval(parts[0]) else {
                continue
            }

            let body = String(parts[1])
            if let event = extractRateLimitEvent(from: body) {
                let snapshot = QuotaSnapshot(
                    event: event,
                    logDate: date(fromDatabaseTimestamp: timestamp),
                    readDate: Date(),
                    source: .codexLogs
                )

                if isCurrentRateLimitEvent(event) {
                    return snapshot
                }
            }
        }

        return nil
    }

    private func loadLogSchema(databasePath: String) throws -> LogSchema? {
        let output = try runSQLite(databasePath: databasePath, query: "pragma table_info(logs);")
        let columns = output
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { line -> SQLiteColumn? in
                let parts = line.split(separator: "\t", omittingEmptySubsequences: false)
                guard parts.count >= 3 else {
                    return nil
                }
                return SQLiteColumn(name: String(parts[1]), type: String(parts[2]))
            }

        guard !columns.isEmpty else {
            return nil
        }

        let names = columns.map(\.name)
        let timestampColumn = firstExisting(in: names, candidates: ["ts", "timestamp", "created_at", "time", "date"]) ?? "ts"
        let nanosColumn = firstExisting(in: names, candidates: ["ts_nanos", "timestamp_nanos", "nanos"])
        let idColumn = firstExisting(in: names, candidates: ["id", "rowid"])
        let bodyColumn = firstExisting(
            in: names,
            candidates: ["feedback_log_body", "body", "message", "text", "payload", "event", "json"]
        ) ?? columns.first { column in
            column.type.localizedCaseInsensitiveContains("text")
                && ["body", "message", "payload", "event", "json", "log"].contains { namePart in
                    column.name.localizedCaseInsensitiveContains(namePart)
                }
        }?.name

        guard names.contains(timestampColumn), let bodyColumn, names.contains(bodyColumn) else {
            return nil
        }

        return LogSchema(
            timestampColumn: timestampColumn,
            timestampNanosColumn: nanosColumn,
            idColumn: idColumn,
            bodyColumn: bodyColumn
        )
    }

    private func isCurrentRateLimitEvent(_ event: RateLimitEvent) -> Bool {
        (event.rateLimits.weekly?.resetDate ?? .distantPast) > Date()
    }

    private func runSQLite(databasePath: String, query: String) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: sqlitePath)
        process.arguments = ["-readonly", "-separator", "\t", databasePath, query]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
        } catch {
            throw QuotaReadError.cannotRunSQLite(error.localizedDescription)
        }
        process.waitUntilExit()

        let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let errorOutput = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

        guard process.terminationStatus == 0 else {
            throw QuotaReadError.sqliteFailed(errorOutput.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        return output
    }

    private func firstExisting(in names: [String], candidates: [String]) -> String? {
        for candidate in candidates {
            if names.contains(candidate) {
                return candidate
            }
        }

        return nil
    }

    private func quoteIdentifier(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    private func date(fromDatabaseTimestamp timestamp: TimeInterval) -> Date {
        if timestamp > 10_000_000_000 {
            return Date(timeIntervalSince1970: timestamp / 1000)
        }

        return Date(timeIntervalSince1970: timestamp)
    }

    private func extractRateLimitEvent(from body: String) -> RateLimitEvent? {
        let needles = ["{\"type\":\"codex.rate_limits\"", "{\\\"type\\\":\\\"codex.rate_limits\\\""]
        let maxCandidateLength = 100_000

        for needle in needles {
            var searchStart = body.startIndex
            while let range = body.range(of: needle, range: searchStart..<body.endIndex) {
                let candidateEnd = body.index(
                    range.lowerBound,
                    offsetBy: maxCandidateLength,
                    limitedBy: body.endIndex
                ) ?? body.endIndex
                let rawCandidate = String(body[range.lowerBound..<candidateEnd])
                let candidate: String
                if needle.contains("\\\"") {
                    candidate = rawCandidate
                        .replacingOccurrences(of: "\\\"", with: "\"")
                        .replacingOccurrences(of: "\\\\", with: "\\")
                } else {
                    candidate = rawCandidate
                }

                if let event = decodeJSONPrefix(candidate), event.type == "codex.rate_limits" {
                    return event
                }

                searchStart = body.index(after: range.lowerBound)
            }
        }

        return nil
    }

    private func decodeJSONPrefix(_ text: String) -> RateLimitEvent? {
        let decoder = JSONDecoder()
        var depth = 0
        var inString = false
        var isEscaped = false

        for (offset, character) in text.enumerated() {
            if inString {
                if isEscaped {
                    isEscaped = false
                } else if character == "\\" {
                    isEscaped = true
                } else if character == "\"" {
                    inString = false
                }
                continue
            }

            if character == "\"" {
                inString = true
            } else if character == "{" {
                depth += 1
            } else if character == "}" {
                depth -= 1
                if depth == 0 {
                    let endIndex = text.index(text.startIndex, offsetBy: offset + 1)
                    let jsonText = String(text[..<endIndex])
                    guard let data = jsonText.data(using: .utf8) else {
                        return nil
                    }
                    return try? decoder.decode(RateLimitEvent.self, from: data)
                }
            }
        }

        return nil
    }

    func diagnostics() -> String {
        var lines = [
            "CodexVisual diagnostics",
            "Home: \(NSHomeDirectory())",
            "Sessions: \(sessionsDirectory.path)",
            "Sessions exists: \(FileManager.default.fileExists(atPath: sessionsDirectory.path))",
            "Checked databases:"
        ]

        if let sessionSnapshot = readFromSessions() {
            if let weekly = sessionSnapshot.event.rateLimits.weekly {
                lines.append("Latest session weekly quota: \(weekly.remainingPercent)%")
            }
            lines.append("Latest session quota read date: \(sessionSnapshot.logDate)")
        }

        for databasePath in databasePaths {
            let exists = FileManager.default.fileExists(atPath: databasePath)
            lines.append("- \(databasePath)")
            lines.append("  exists: \(exists)")

            guard exists else {
                continue
            }

            if let attributes = try? FileManager.default.attributesOfItem(atPath: databasePath) {
                if let size = attributes[.size] as? NSNumber {
                    lines.append("  size: \(size.int64Value) bytes")
                }
                if let modified = attributes[.modificationDate] as? Date {
                    lines.append("  modified: \(modified)")
                }
            }

            if let total = try? runSQLite(databasePath: databasePath, query: "select count(*) from logs;")
                .trimmingCharacters(in: .whitespacesAndNewlines) {
                lines.append("  log rows: \(total)")
            }

            if let schema = try? loadLogSchema(databasePath: databasePath) {
                lines.append("  detected timestamp column: \(schema.timestampColumn)")
                lines.append("  detected body column: \(schema.bodyColumn)")
                if let candidates = try? runSQLite(
                    databasePath: databasePath,
                    query: "select count(*) from logs where \(quoteIdentifier(schema.bodyColumn)) like '%codex.rate_limits%';"
                ).trimmingCharacters(in: .whitespacesAndNewlines) {
                    lines.append("  codex.rate_limits candidates: \(candidates)")
                }
            }
        }

        lines.append("Cache: \(cacheURL.path)")
        lines.append("Cache exists: \(FileManager.default.fileExists(atPath: cacheURL.path))")
        lines.append("Legacy cache: \(legacyCacheURL.path)")
        lines.append("Legacy cache exists: \(FileManager.default.fileExists(atPath: legacyCacheURL.path))")
        return lines.joined(separator: "\n")
    }

    private var cacheURL: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return support.appendingPathComponent("CodexVisual/latest-rate-limit.json")
    }

    private var legacyCacheURL: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return support.appendingPathComponent("CodexQuotaBar/latest-rate-limit.json")
    }

    private func saveCache(snapshot: QuotaSnapshot) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let payload = CachedSnapshot(
                schemaVersion: CachedSnapshot.currentSchemaVersion,
                event: snapshot.event,
                logTimestamp: snapshot.logDate.timeIntervalSince1970,
                cachedTimestamp: Date().timeIntervalSince1970,
                source: snapshot.source.rawValue
            )
            let data = try encoder.encode(payload)
            try FileManager.default.createDirectory(at: cacheURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: cacheURL, options: .atomic)
        } catch {
            // Cache failures should not hide live quota data.
        }
    }

    private func readCache() -> QuotaSnapshot? {
        readCache(at: cacheURL, source: .localCache)
            ?? readCache(at: legacyCacheURL, source: .migratedCache)
    }

    private func readCache(at url: URL, source: SnapshotSource) -> QuotaSnapshot? {
        do {
            let data = try Data(contentsOf: url)
            let cached = try JSONDecoder().decode(CachedSnapshot.self, from: data)
            guard cached.schemaVersion == CachedSnapshot.currentSchemaVersion,
                  cached.source == SnapshotSource.codexLogs.rawValue || cached.source == SnapshotSource.codexSessions.rawValue else {
                return nil
            }
            guard isCurrentRateLimitEvent(cached.event), isUsefulRateLimitEvent(cached.event) else {
                return nil
            }
            return QuotaSnapshot(
                event: cached.event,
                logDate: Date(timeIntervalSince1970: cached.logTimestamp),
                readDate: Date(),
                source: source
            )
        } catch {
            return nil
        }
    }
}

struct SQLiteColumn {
    let name: String
    let type: String
}

struct LogSchema {
    let timestampColumn: String
    let timestampNanosColumn: String?
    let idColumn: String?
    let bodyColumn: String
}

struct SessionMetaLogEntry: Decodable {
    let type: String
    let payload: SessionMetaPayload
}

struct SessionMetaPayload: Decodable {
    let threadSource: String?
    let source: SessionSource?

    enum CodingKeys: String, CodingKey {
        case threadSource = "thread_source"
        case source
    }
}

enum SessionSource: Decodable {
    case string(String)
    case object(hasSubagent: Bool)

    var isSubagent: Bool {
        switch self {
        case .string:
            return false
        case .object(let hasSubagent):
            return hasSubagent
        }
    }

    init(from decoder: Decoder) throws {
        if let string = try? decoder.singleValueContainer().decode(String.self) {
            self = .string(string)
            return
        }

        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        self = .object(hasSubagent: container.contains(DynamicCodingKey(stringValue: "subagent")!))
    }
}

struct DynamicCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

struct SessionLogEntry: Decodable {
    let timestamp: String
    let payload: SessionPayload
}

struct SessionPayload: Decodable {
    let type: String?
    let rateLimits: SessionRateLimits?

    enum CodingKeys: String, CodingKey {
        case type
        case rateLimits = "rate_limits"
    }
}

struct SessionRateLimits: Decodable {
    let planType: String?
    let primary: SessionQuotaWindow?
    let secondary: SessionQuotaWindow?
    let rateLimitReachedType: String?

    enum CodingKeys: String, CodingKey {
        case planType = "plan_type"
        case primary
        case secondary
        case rateLimitReachedType = "rate_limit_reached_type"
    }
}

struct SessionQuotaWindow: Decodable {
    let usedPercent: Double
    let windowMinutes: Int
    let resetsAt: TimeInterval

    enum CodingKeys: String, CodingKey {
        case usedPercent = "used_percent"
        case windowMinutes = "window_minutes"
        case resetsAt = "resets_at"
    }
}

struct CachedSnapshot: Codable {
    static let currentSchemaVersion = 3

    let schemaVersion: Int
    let event: RateLimitEvent
    let logTimestamp: TimeInterval
    let cachedTimestamp: TimeInterval
    let source: String
}

struct GitHubRelease: Decodable {
    let tagName: String
    let assets: [GitHubAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case assets
    }
}

struct GitHubAsset: Decodable {
    let name: String
    let browserDownloadURL: URL

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
    }
}

struct UpdateInfo {
    let version: String
    let downloadURL: URL
}

enum QuotaColor {
    static func fill(for remaining: Int) -> NSColor {
        if remaining < 20 {
            return NSColor(calibratedRed: 1.00, green: 0.23, blue: 0.19, alpha: 1)
        }

        if remaining <= 50 {
            return NSColor(calibratedRed: 1.00, green: 0.64, blue: 0.00, alpha: 1)
        }

        if remaining <= 80 {
            return NSColor(calibratedRed: 0.02, green: 0.48, blue: 1.00, alpha: 1)
        }

        return NSColor(calibratedRed: 0.12, green: 0.84, blue: 0.42, alpha: 1)
    }

    static func statusText(for remaining: Int) -> NSColor {
        if remaining < 20 {
            return NSColor(calibratedRed: 1.00, green: 0.38, blue: 0.36, alpha: 1)
        }

        if remaining <= 50 {
            return NSColor(calibratedRed: 1.00, green: 0.76, blue: 0.20, alpha: 1)
        }

        if remaining <= 80 {
            return NSColor(calibratedRed: 0.36, green: 0.68, blue: 1.00, alpha: 1)
        }

        return NSColor(calibratedRed: 0.34, green: 0.94, blue: 0.62, alpha: 1)
    }

    static func background(for remaining: Int) -> NSColor {
        fill(for: remaining).withAlphaComponent(remaining < 20 ? 0.13 : 0.11)
    }
}

final class QuotaProgressView: NSView {
    private let trackLayer = CALayer()
    private let fillLayer = CALayer()
    private var value: CGFloat = 0

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        wantsLayer = true
        layer?.masksToBounds = false
        trackLayer.backgroundColor = NSColor.separatorColor.withAlphaComponent(0.45).cgColor
        fillLayer.backgroundColor = NSColor.controlAccentColor.cgColor
        layer?.addSublayer(trackLayer)
        layer?.addSublayer(fillLayer)
    }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let cornerRadius = bounds.height / 2
        trackLayer.frame = bounds
        trackLayer.cornerRadius = cornerRadius
        fillLayer.frame = CGRect(x: 0, y: 0, width: bounds.width * value, height: bounds.height)
        fillLayer.cornerRadius = cornerRadius
        CATransaction.commit()
    }

    func update(remaining: Int, color: NSColor) {
        value = CGFloat(min(100, max(0, remaining))) / 100
        fillLayer.backgroundColor = color.cgColor
        needsLayout = true
    }
}

final class QuotaWindowView: NSView {
    private let nameLabel = NSTextField(labelWithString: "")
    private let percentValueLabel = NSTextField(labelWithString: "")
    private let percentSymbolLabel = NSTextField(labelWithString: "%")
    private let usedLabel = NSTextField(labelWithString: "")
    private let resetLabel = NSTextField(labelWithString: "")
    private let progress = QuotaProgressView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: 72)
    }

    private func configure() {
        wantsLayer = true
        layer?.cornerRadius = 8
        layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.10).cgColor

        nameLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        nameLabel.textColor = .labelColor

        percentValueLabel.font = .monospacedDigitSystemFont(ofSize: 25, weight: .bold)
        percentValueLabel.textColor = .labelColor
        percentValueLabel.alignment = .right
        percentValueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        percentSymbolLabel.font = .monospacedDigitSystemFont(ofSize: 16, weight: .bold)
        percentSymbolLabel.textColor = .labelColor
        percentSymbolLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        usedLabel.font = .systemFont(ofSize: 11, weight: .medium)
        usedLabel.textColor = .secondaryLabelColor
        usedLabel.lineBreakMode = .byTruncatingTail
        usedLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        resetLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        resetLabel.textColor = .secondaryLabelColor
        resetLabel.alignment = .right
        resetLabel.lineBreakMode = .byTruncatingTail
        resetLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let percentStack = NSStackView(views: [percentValueLabel, percentSymbolLabel])
        percentStack.orientation = .horizontal
        percentStack.alignment = .firstBaseline
        percentStack.spacing = 3

        percentStack.setContentCompressionResistancePriority(.required, for: .horizontal)

        let topStack = NSStackView(views: [nameLabel, NSView(), percentStack])
        topStack.orientation = .horizontal
        topStack.alignment = .centerY
        topStack.spacing = 6

        let detailStack = NSStackView(views: [usedLabel, NSView(), resetLabel])
        detailStack.orientation = .horizontal
        detailStack.alignment = .centerY
        detailStack.spacing = 8

        let stack = NSStackView(views: [topStack, progress, detailStack])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 5
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 9),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -9),
            progress.widthAnchor.constraint(equalTo: stack.widthAnchor),
            progress.heightAnchor.constraint(equalToConstant: 5),
            detailStack.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
    }

    func update(name: String, remaining: Int, used: Int, resetText: String) {
        nameLabel.stringValue = name
        percentValueLabel.stringValue = "\(remaining)"
        usedLabel.stringValue = AppStrings.usedCompact(used)
        resetLabel.stringValue = AppStrings.resetCompact(resetText)
        progress.update(remaining: remaining, color: QuotaColor.fill(for: remaining))
        layer?.backgroundColor = QuotaColor.background(for: remaining).cgColor
    }
}

final class QuotaOverviewView: NSView {
    private let titleLabel = NSTextField(labelWithString: "")
    private let planLabel = NSTextField(labelWithString: "")
    private let weeklyView = QuotaWindowView()
    private let sourceLabel = NSTextField(labelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 420, height: 150)
    }

    private func configure() {
        frame.size = intrinsicContentSize

        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .labelColor

        planLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .semibold)
        planLabel.textColor = .secondaryLabelColor
        planLabel.alignment = .right

        sourceLabel.font = .systemFont(ofSize: 10.5, weight: .regular)
        sourceLabel.textColor = .secondaryLabelColor
        sourceLabel.lineBreakMode = .byTruncatingTail
        sourceLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        let header = NSStackView(views: [titleLabel, NSView(), planLabel])
        header.orientation = .horizontal
        header.alignment = .centerY
        header.spacing = 10

        let stack = NSStackView(views: [header, weeklyView, sourceLabel])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            header.widthAnchor.constraint(equalTo: stack.widthAnchor),
            weeklyView.widthAnchor.constraint(equalTo: stack.widthAnchor),
            weeklyView.heightAnchor.constraint(equalToConstant: 72),
            sourceLabel.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
    }

    func update(snapshot: QuotaSnapshot, plan: String, timeFormatter: DateFormatter, shortTimeFormatter: DateFormatter) {
        guard let weekly = snapshot.event.rateLimits.weekly else {
            return
        }

        titleLabel.stringValue = AppStrings.quotaOverview
        planLabel.stringValue = AppStrings.plan(plan)
        weeklyView.update(
            name: AppStrings.weeklyQuota,
            remaining: weekly.remainingPercent,
            used: weekly.effectiveUsedPercent,
            resetText: resetText(for: weekly.resetDate, timeFormatter: timeFormatter)
        )
        sourceLabel.stringValue = AppStrings.sourceCompact(
            source: snapshot.source.title,
            readTime: shortTimeFormatter.string(from: snapshot.readDate)
        )
    }

    private func resetText(for date: Date, timeFormatter: DateFormatter) -> String {
        let seconds = date.timeIntervalSinceNow
        if seconds > 0, seconds < 3600 {
            let rounded = max(0, Int(ceil(seconds)))
            return String(format: "%02d:%02d", rounded / 60, rounded % 60)
        }

        if seconds <= 0 {
            return AppStrings.resetPending
        }

        let hourMinuteFormatter = DateFormatter()
        hourMinuteFormatter.locale = timeFormatter.locale
        hourMinuteFormatter.dateFormat = "HH:mm"

        let dateTimeFormatter = DateFormatter()
        dateTimeFormatter.locale = timeFormatter.locale
        dateTimeFormatter.dateFormat = AppStrings.usesChinese ? "M月d日 E HH:mm" : "EEE MMM d HH:mm"

        if Calendar.current.isDateInToday(date) {
            return AppStrings.text(
                "今天 \(dateTimeFormatter.string(from: date))",
                "Today \(hourMinuteFormatter.string(from: date))"
            )
        }

        if Calendar.current.isDateInTomorrow(date) {
            return AppStrings.text(
                "明天 \(dateTimeFormatter.string(from: date))",
                "Tomorrow \(dateTimeFormatter.string(from: date))"
            )
        }

        return timeFormatter.string(from: date)
    }
}

enum QuotaStatusImage {
    static let size = NSSize(width: 166, height: 22)

    static func make(weekly: Int, weeklyReset: Date) -> NSImage {
        let image = NSImage(size: size)
        image.cacheMode = .never
        image.lockFocus()
        defer { image.unlockFocus() }

        let background = NSBezierPath(roundedRect: NSRect(x: 0, y: 1, width: size.width, height: size.height - 2), xRadius: 6, yRadius: 6)
        NSColor.controlAccentColor.withAlphaComponent(0.16).setFill()
        background.fill()

        drawRow(label: "7d", remaining: weekly, resetText: resetShortText(for: weeklyReset), y: 5)

        image.isTemplate = false
        return image
    }

    private static func drawRow(label: String, remaining: Int, resetText: String, y: CGFloat) {
        let secondaryColor = NSColor.secondaryLabelColor
        let barColor = MenuBarTextGroup.bar.currentColor.resolvedForBar(for: remaining)
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 9.4, weight: .bold),
            .foregroundColor: MenuBarTextGroup.label.currentColor.resolved(for: remaining)
        ]
        let percentAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 10.4, weight: .heavy),
            .foregroundColor: MenuBarTextGroup.percent.currentColor.resolved(for: remaining)
        ]
        let resetAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 8.6, weight: .heavy),
            .foregroundColor: MenuBarTextGroup.reset.currentColor.resolved(for: remaining)
        ]

        (label as NSString).draw(at: NSPoint(x: 8, y: y - 1), withAttributes: labelAttributes)

        let barRect = NSRect(x: 26, y: y + 1.5, width: 58, height: 5)
        let trackPath = NSBezierPath(roundedRect: barRect, xRadius: 2, yRadius: 2)
        secondaryColor.withAlphaComponent(0.28).setFill()
        trackPath.fill()

        let progressWidth = barRect.width * CGFloat(min(100, max(0, remaining))) / 100
        let fillRect = NSRect(x: barRect.minX, y: barRect.minY, width: progressWidth, height: barRect.height)
        let fillPath = NSBezierPath(roundedRect: fillRect, xRadius: 2, yRadius: 2)
        barColor.setFill()
        fillPath.fill()

        ("\(remaining)%" as NSString).draw(at: NSPoint(x: 90, y: y - 1.5), withAttributes: percentAttributes)
        (resetText as NSString).draw(at: NSPoint(x: 126, y: y - 0.6), withAttributes: resetAttributes)
    }

    private static func resetShortText(for date: Date) -> String {
        let seconds = date.timeIntervalSinceNow
        if seconds <= 0 {
            return "now"
        }

        let minutes = max(1, Int(floor(seconds / 60)))
        if minutes < 60 {
            return "\(minutes)m"
        }

        let hours = minutes / 60
        let remainderMinutes = minutes % 60
        if hours < 24 {
            return remainderMinutes == 0 ? "\(hours)h" : "\(hours)h\(remainderMinutes)m"
        }

        let days = hours / 24
        let remainderHours = hours % 24
        if days >= 10 || remainderHours == 0 {
            return "\(days)d"
        }

        return "\(days)d\(remainderHours)h"
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let reader = QuotaReader()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private let overviewItem = NSMenuItem()
    private let overviewView = QuotaOverviewView()
    private let orderItem = NSMenuItem()
    private let planItem = NSMenuItem()
    private let logTimeItem = NSMenuItem()
    private let readTimeItem = NSMenuItem()
    private let errorItem = NSMenuItem()
    private let languageItem = NSMenuItem()
    private let languageMenu = NSMenu()
    private let systemLanguageItem = NSMenuItem()
    private let englishLanguageItem = NSMenuItem()
    private let chineseLanguageItem = NSMenuItem()
    private let refreshFrequencyItem = NSMenuItem()
    private let refreshFrequencyMenu = NSMenu()
    private let smartRefreshItem = NSMenuItem()
    private let fiveSecondRefreshItem = NSMenuItem()
    private let fifteenSecondRefreshItem = NSMenuItem()
    private let sixtySecondRefreshItem = NSMenuItem()
    private let fiveMinuteRefreshItem = NSMenuItem()
    private let manualRefreshItem = NSMenuItem()
    private let menuBarDisplayItem = NSMenuItem()
    private let menuBarDisplayMenu = NSMenu()
    private let barsDisplayItem = NSMenuItem()
    private let numbersDisplayItem = NSMenuItem()
    private let menuBarTextColorItem = NSMenuItem()
    private let menuBarTextColorMenu = NSMenu()
    private var menuBarTextColorItems: [MenuBarTextGroup: [MenuBarTextColor: NSMenuItem]] = [:]
    private let openDashboardItem = NSMenuItem()
    private let refreshItem = NSMenuItem()
    private let checkUpdatesItem = NSMenuItem()
    private let uninstallItem = NSMenuItem()
    private let quitItem = NSMenuItem()
    private var timer: Timer?
    private var latestSnapshot: QuotaSnapshot?
    private var controlWindow: NSWindow?
    private let windowOverviewView = QuotaOverviewView()
    private let windowErrorLabel = NSTextField(wrappingLabelWithString: AppStrings.noQuotaYet)
    private let windowRefreshButton = NSButton()
    private let windowUpdateButton = NSButton()
    private let windowUninstallButton = NSButton()
    private let windowQuitButton = NSButton()

    private var quotaDetailItems: [NSMenuItem] {
        [overviewItem]
    }

    private lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = AppStrings.dateLocale
        formatter.dateFormat = AppStrings.dateFormat
        return formatter
    }()

    private lazy var shortTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = AppStrings.dateLocale
        formatter.dateFormat = AppStrings.shortTimeFormat
        return formatter
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureMenu()
        refresh(nil)
        showControlWindow()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showControlWindow()
        return false
    }

    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow === controlWindow {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    private func configureMenu() {
        configureStatusButton()
        statusItem.menu = menu
        statusItem.button?.title = AppStrings.statusTitlePlaceholder
        overviewItem.view = overviewView
        overviewItem.isHidden = true
        menu.addItem(overviewItem)

        errorItem.isHidden = true
        errorItem.isEnabled = false
        errorItem.title = " "
        menu.addItem(errorItem)

        menu.addItem(.separator())
        configureLanguageMenu()
        menu.addItem(languageItem)
        configureRefreshFrequencyMenu()
        menu.addItem(refreshFrequencyItem)
        configureMenuBarDisplayMenu()
        menu.addItem(menuBarDisplayItem)
        configureMenuBarTextColorMenu()
        menu.addItem(menuBarTextColorItem)

        menu.addItem(.separator())
        openDashboardItem.action = #selector(openDashboard(_:))
        openDashboardItem.target = self
        menu.addItem(openDashboardItem)

        refreshItem.action = #selector(refresh(_:))
        refreshItem.keyEquivalent = "r"
        refreshItem.target = self
        menu.addItem(refreshItem)

        checkUpdatesItem.action = #selector(checkForUpdates(_:))
        checkUpdatesItem.target = self
        menu.addItem(checkUpdatesItem)

        menu.addItem(.separator())
        uninstallItem.action = #selector(uninstall(_:))
        uninstallItem.target = self
        menu.addItem(uninstallItem)

        quitItem.action = #selector(quit(_:))
        quitItem.keyEquivalent = "q"
        quitItem.target = self
        menu.addItem(quitItem)

        updateStaticMenuText()
        updateLanguageMenuState()
        updateRefreshModeMenuState()
        updateMenuBarDisplayModeMenuState()
        updateMenuBarTextColorMenuState()
    }

    private func configureStatusButton() {
        guard let button = statusItem.button else {
            return
        }

        statusItem.length = NSStatusItem.variableLength
        button.title = AppStrings.statusTitlePlaceholder
        button.image = nil
        button.imagePosition = .noImage
        button.imageScaling = .scaleProportionallyDown
    }

    private func configureLanguageMenu() {
        languageItem.submenu = languageMenu

        systemLanguageItem.action = #selector(selectSystemLanguage(_:))
        systemLanguageItem.target = self
        englishLanguageItem.action = #selector(selectEnglishLanguage(_:))
        englishLanguageItem.target = self
        chineseLanguageItem.action = #selector(selectChineseLanguage(_:))
        chineseLanguageItem.target = self

        languageMenu.addItem(systemLanguageItem)
        languageMenu.addItem(englishLanguageItem)
        languageMenu.addItem(chineseLanguageItem)
    }

    private func configureRefreshFrequencyMenu() {
        refreshFrequencyItem.submenu = refreshFrequencyMenu

        let pairs: [(NSMenuItem, RefreshMode)] = [
            (smartRefreshItem, .smart),
            (fiveSecondRefreshItem, .everyFiveSeconds),
            (fifteenSecondRefreshItem, .everyFifteenSeconds),
            (sixtySecondRefreshItem, .everySixtySeconds),
            (fiveMinuteRefreshItem, .everyFiveMinutes),
            (manualRefreshItem, .manual)
        ]

        for (item, mode) in pairs {
            item.action = #selector(selectRefreshMode(_:))
            item.target = self
            item.representedObject = mode.rawValue
            refreshFrequencyMenu.addItem(item)
        }
    }

    private func configureMenuBarDisplayMenu() {
        menuBarDisplayItem.submenu = menuBarDisplayMenu

        let pairs: [(NSMenuItem, MenuBarDisplayMode)] = [
            (barsDisplayItem, .bars),
            (numbersDisplayItem, .numbers)
        ]

        for (item, mode) in pairs {
            item.action = #selector(selectMenuBarDisplayMode(_:))
            item.target = self
            item.representedObject = mode.rawValue
            menuBarDisplayMenu.addItem(item)
        }
    }

    private func configureMenuBarTextColorMenu() {
        menuBarTextColorItem.submenu = menuBarTextColorMenu

        for group in MenuBarTextGroup.allCases {
            let groupItem = NSMenuItem()
            let groupMenu = NSMenu()
            groupItem.submenu = groupMenu

            var colorItems: [MenuBarTextColor: NSMenuItem] = [:]
            for color in MenuBarTextColor.allCases {
                let item = NSMenuItem()
                item.action = #selector(selectMenuBarTextColor(_:))
                item.target = self
                item.representedObject = "\(group.rawValue)|\(color.rawValue)"
                item.image = menuColorPreview(for: color)
                groupMenu.addItem(item)
                colorItems[color] = item
            }

            menuBarTextColorMenu.addItem(groupItem)
            menuBarTextColorItems[group] = colorItems
        }
    }

    private func updateDateFormatters() {
        timeFormatter.locale = AppStrings.dateLocale
        timeFormatter.dateFormat = AppStrings.dateFormat
        shortTimeFormatter.locale = AppStrings.dateLocale
        shortTimeFormatter.dateFormat = AppStrings.shortTimeFormat
    }

    private func updateStaticMenuText() {
        updateDateFormatters()
        statusItem.button?.toolTip = latestSnapshot
            .flatMap { snapshot in snapshot.event.rateLimits.weekly }
            .map { weekly in AppStrings.quotaToolTip(weekly: weekly.remainingPercent) }
            ?? AppStrings.statusToolTip
        orderItem.title = AppStrings.displayOrder
        languageItem.title = AppStrings.language
        systemLanguageItem.title = AppStrings.languageSystem
        englishLanguageItem.title = AppStrings.languageEnglish
        chineseLanguageItem.title = AppStrings.languageChinese
        refreshFrequencyItem.title = AppStrings.refreshFrequency
        smartRefreshItem.title = AppStrings.refreshSmart
        fiveSecondRefreshItem.title = AppStrings.refreshEvery5Seconds
        fifteenSecondRefreshItem.title = AppStrings.refreshEvery15Seconds
        sixtySecondRefreshItem.title = AppStrings.refreshEvery60Seconds
        fiveMinuteRefreshItem.title = AppStrings.refreshEvery5Minutes
        manualRefreshItem.title = AppStrings.refreshManual
        menuBarDisplayItem.title = AppStrings.menuBarDisplay
        barsDisplayItem.title = AppStrings.menuBarDisplayBars
        numbersDisplayItem.title = AppStrings.menuBarDisplayNumbers
        menuBarTextColorItem.title = AppStrings.menuBarTextColor
        for group in MenuBarTextGroup.allCases {
            menuBarTextColorMenu.items.first(where: { $0.submenu?.items.contains(where: { item in
                (item.representedObject as? String)?.hasPrefix("\(group.rawValue)|") == true
            }) == true })?.title = title(for: group)

            for color in MenuBarTextColor.allCases {
                menuBarTextColorItems[group]?[color]?.title = title(for: color)
            }
        }
        openDashboardItem.title = AppStrings.openDashboard
        refreshItem.title = AppStrings.refreshNow
        checkUpdatesItem.title = AppStrings.checkForUpdates
        uninstallItem.title = AppStrings.uninstall
        quitItem.title = AppStrings.quit
        windowRefreshButton.title = AppStrings.refreshNow
        windowUpdateButton.title = AppStrings.checkForUpdates
        windowUninstallButton.title = AppStrings.uninstall
        windowQuitButton.title = AppStrings.quit
        windowErrorLabel.stringValue = AppStrings.noQuotaYet
        controlWindow?.title = AppStrings.controlWindowTitle
    }

    private func updateLanguageMenuState() {
        let currentMode = LanguageMode.current
        systemLanguageItem.state = currentMode == .system ? .on : .off
        englishLanguageItem.state = currentMode == .english ? .on : .off
        chineseLanguageItem.state = currentMode == .chinese ? .on : .off
    }

    private func updateRefreshModeMenuState() {
        let currentMode = RefreshMode.current
        let pairs: [(NSMenuItem, RefreshMode)] = [
            (smartRefreshItem, .smart),
            (fiveSecondRefreshItem, .everyFiveSeconds),
            (fifteenSecondRefreshItem, .everyFifteenSeconds),
            (sixtySecondRefreshItem, .everySixtySeconds),
            (fiveMinuteRefreshItem, .everyFiveMinutes),
            (manualRefreshItem, .manual)
        ]

        for (item, mode) in pairs {
            item.state = currentMode == mode ? .on : .off
        }
    }

    private func updateMenuBarDisplayModeMenuState() {
        let currentMode = MenuBarDisplayMode.current
        let pairs: [(NSMenuItem, MenuBarDisplayMode)] = [
            (barsDisplayItem, .bars),
            (numbersDisplayItem, .numbers)
        ]

        for (item, mode) in pairs {
            item.state = currentMode == mode ? .on : .off
        }
    }

    private func updateMenuBarTextColorMenuState() {
        for group in MenuBarTextGroup.allCases {
            let currentColor = group.currentColor
            for color in MenuBarTextColor.allCases {
                menuBarTextColorItems[group]?[color]?.state = currentColor == color ? .on : .off
            }
        }
    }

    private func title(for group: MenuBarTextGroup) -> String {
        switch group {
        case .bar:
            return AppStrings.menuBarTextBar
        case .label:
            return AppStrings.menuBarTextLabel
        case .percent:
            return AppStrings.menuBarTextPercent
        case .reset:
            return AppStrings.menuBarTextReset
        }
    }

    private func title(for color: MenuBarTextColor) -> String {
        switch color {
        case .quota:
            return AppStrings.colorQuota
        case .white:
            return AppStrings.colorWhite
        case .blue:
            return AppStrings.colorBlue
        case .green:
            return AppStrings.colorGreen
        case .yellow:
            return AppStrings.colorYellow
        case .red:
            return AppStrings.colorRed
        case .gray:
            return AppStrings.colorGray
        }
    }

    private func menuColorPreview(for color: MenuBarTextColor) -> NSImage {
        let size = NSSize(width: 18, height: 14)
        let image = NSImage(size: size)

        image.lockFocus()
        defer { image.unlockFocus() }

        let rect = NSRect(x: 2, y: 3, width: 14, height: 8)
        let path = NSBezierPath(roundedRect: rect, xRadius: 3, yRadius: 3)
        NSColor.clear.setFill()
        NSRect(origin: .zero, size: size).fill()

        if color == .quota {
            let colors = color.previewColors
            let segmentWidth = rect.width / CGFloat(colors.count)
            NSGraphicsContext.saveGraphicsState()
            path.addClip()
            for (index, previewColor) in colors.enumerated() {
                let segmentRect = NSRect(
                    x: rect.minX + CGFloat(index) * segmentWidth,
                    y: rect.minY,
                    width: index == colors.count - 1 ? rect.maxX - (rect.minX + CGFloat(index) * segmentWidth) : segmentWidth,
                    height: rect.height
                )
                previewColor.setFill()
                segmentRect.fill()
            }
            NSGraphicsContext.restoreGraphicsState()
        } else {
            color.previewColors.first?.setFill()
            path.fill()
        }

        NSColor.separatorColor.withAlphaComponent(0.75).setStroke()
        path.lineWidth = 0.8
        path.stroke()

        image.isTemplate = false
        return image
    }

    @objc private func refresh(_ sender: Any?) {
        do {
            let snapshot = try reader.readLatest(allowCache: sender == nil)
            update(snapshot)
        } catch {
            statusItem.length = NSStatusItem.variableLength
            statusItem.button?.image = nil
            statusItem.button?.imagePosition = .noImage
            statusItem.button?.title = AppStrings.statusTitlePlaceholder
            statusItem.button?.toolTip = error.localizedDescription
            for item in quotaDetailItems {
                item.isHidden = true
            }
            errorItem.title = error.localizedDescription
            errorItem.isHidden = false
            updateWindow(error: error.localizedDescription)
        }

        scheduleNextRefresh()
    }

    private func scheduleNextRefresh() {
        timer?.invalidate()
        timer = nil

        guard let interval = nextRefreshInterval() else {
            return
        }

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.refresh(nil)
            }
        }
    }

    private func nextRefreshInterval() -> TimeInterval? {
        guard var interval = RefreshMode.current.baseInterval else {
            return nil
        }

        if let snapshot = latestSnapshot {
            let resetDates = snapshot.event.rateLimits.weekly.map { [$0.resetDate] } ?? []

            for resetDate in resetDates {
                let secondsUntilReset = resetDate.timeIntervalSinceNow
                if secondsUntilReset > 0, secondsUntilReset < interval {
                    interval = max(2, secondsUntilReset + 2)
                }
            }
        }

        return interval
    }

    @objc private func openDashboard(_ sender: Any?) {
        showControlWindow()
    }

    private func showControlWindow() {
        if controlWindow == nil {
            configureControlWindow()
        }

        if let snapshot = latestSnapshot {
            updateWindow(snapshot)
        } else {
            windowOverviewView.isHidden = true
            windowErrorLabel.isHidden = false
        }

        NSApp.setActivationPolicy(.regular)
        controlWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func configureControlWindow() {
        let contentView = NSView()
        contentView.translatesAutoresizingMaskIntoConstraints = false

        windowOverviewView.translatesAutoresizingMaskIntoConstraints = false
        windowOverviewView.isHidden = true

        windowErrorLabel.font = .systemFont(ofSize: 13, weight: .regular)
        windowErrorLabel.textColor = .secondaryLabelColor
        windowErrorLabel.alignment = .center
        windowErrorLabel.translatesAutoresizingMaskIntoConstraints = false

        configureWindowButton(windowRefreshButton, action: #selector(refresh(_:)))
        configureWindowButton(windowUpdateButton, action: #selector(checkForUpdates(_:)))
        configureWindowButton(windowUninstallButton, action: #selector(uninstall(_:)))
        configureWindowButton(windowQuitButton, action: #selector(quit(_:)))

        let buttonStack = NSStackView(views: [
            windowRefreshButton,
            windowUpdateButton,
            windowUninstallButton,
            windowQuitButton
        ])
        buttonStack.orientation = .horizontal
        buttonStack.alignment = .centerY
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 8
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        let stack = NSStackView(views: [windowOverviewView, windowErrorLabel, buttonStack])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -18),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -18),
            windowOverviewView.widthAnchor.constraint(equalToConstant: 420),
            windowErrorLabel.widthAnchor.constraint(equalToConstant: 420),
            windowErrorLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 80),
            buttonStack.widthAnchor.constraint(equalToConstant: 420)
        ])

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 456, height: 316),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = AppStrings.controlWindowTitle
        window.contentView = contentView
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
        controlWindow = window
        updateStaticMenuText()
    }

    private func configureWindowButton(_ button: NSButton, action: Selector) {
        button.bezelStyle = .rounded
        button.controlSize = .regular
        button.target = self
        button.action = action
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 32).isActive = true
    }

    @objc private func checkForUpdates(_ sender: Any?) {
        checkUpdatesItem.title = AppStrings.checkingUpdates
        checkUpdatesItem.isEnabled = false
        windowUpdateButton.title = AppStrings.checkingUpdates
        windowUpdateButton.isEnabled = false

        Task { @MainActor in
            await performUpdateCheck()
        }
    }

    private func performUpdateCheck() async {
        defer {
            checkUpdatesItem.title = AppStrings.checkForUpdates
            checkUpdatesItem.isEnabled = true
            windowUpdateButton.title = AppStrings.checkForUpdates
            windowUpdateButton.isEnabled = true
        }

        do {
            let update = try await fetchLatestUpdateInfo()
            let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"

            guard update.version.compare(currentVersion, options: .numeric) == .orderedDescending else {
                let alert = NSAlert()
                alert.messageText = AppStrings.noUpdateTitle
                alert.informativeText = AppStrings.noUpdateMessage(currentVersion)
                alert.alertStyle = .informational
                alert.addButton(withTitle: "OK")
                alert.runModal()
                return
            }

            let alert = NSAlert()
            alert.messageText = AppStrings.updateAvailableTitle
            alert.informativeText = AppStrings.updateAvailableMessage(update.version)
            alert.alertStyle = .informational
            alert.addButton(withTitle: AppStrings.updateNow)
            alert.addButton(withTitle: AppStrings.cancel)

            guard alert.runModal() == .alertFirstButtonReturn else {
                return
            }

            let started = NSAlert()
            started.messageText = AppStrings.updateStartedTitle
            started.informativeText = AppStrings.updateStartedMessage
            started.alertStyle = .informational
            started.addButton(withTitle: "OK")
            started.runModal()

            launchUpdateInstaller(update: update)
            NSApp.terminate(nil)
        } catch {
            let alert = NSAlert()
            alert.messageText = AppStrings.updateFailedTitle
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    private func fetchLatestUpdateInfo() async throws -> UpdateInfo {
        let releaseURL = URL(string: "https://api.github.com/repos/orangeshushu/CodexVisual/releases/latest")!
        var request = URLRequest(url: releaseURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("CodexVisual", forHTTPHeaderField: "User-Agent")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse,
           !(200..<300).contains(httpResponse.statusCode) {
            throw NSError(
                domain: "CodexVisualUpdate",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "GitHub returned HTTP \(httpResponse.statusCode)"]
            )
        }

        let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
        guard let asset = release.assets.first(where: { $0.name == "CodexVisual.dmg" }) else {
            throw NSError(
                domain: "CodexVisualUpdate",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "CodexVisual.dmg was not found in the latest GitHub release."]
            )
        }

        let version = release.tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
        return UpdateInfo(version: version, downloadURL: asset.browserDownloadURL)
    }

    private func launchUpdateInstaller(update: UpdateInfo) {
        let scriptURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("update-codexvisual-\(UUID().uuidString).sh")
        let downloadURL = shellQuote(update.downloadURL.absoluteString)
        let version = shellQuote(update.version)
        let script = """
        #!/bin/zsh
        set -euo pipefail

        DMG_URL=\(downloadURL)
        VERSION=\(version)
        WORK_DIR="$TMPDIR/CodexVisual-update-$VERSION"
        DMG_PATH="$WORK_DIR/CodexVisual.dmg"
        MOUNT_DIR="$WORK_DIR/mount"
        INSTALL_DIR="$HOME/Applications"
        INSTALL_APP="$INSTALL_DIR/CodexVisual.app"

        /bin/rm -rf "$WORK_DIR"
        /bin/mkdir -p "$WORK_DIR" "$MOUNT_DIR" "$INSTALL_DIR"
        /usr/bin/curl -L --fail --silent --show-error -o "$DMG_PATH" "$DMG_URL"
        /usr/sbin/spctl -a -t install "$DMG_PATH"
        /usr/bin/hdiutil attach -nobrowse -readonly -mountpoint "$MOUNT_DIR" "$DMG_PATH" >/dev/null
        /usr/bin/pkill -x "CodexVisual" 2>/dev/null || true
        /bin/rm -rf "$INSTALL_APP"
        /bin/rm -rf "$HOME/Applications/CodexQuotaBar.app"
        /bin/rm -rf "$HOME/Applications/Codex Visual.app"
        /usr/bin/ditto "$MOUNT_DIR/CodexVisual.app" "$INSTALL_APP"
        /usr/bin/xattr -dr com.apple.quarantine "$INSTALL_APP" 2>/dev/null || true
        /usr/bin/hdiutil detach "$MOUNT_DIR" >/dev/null 2>&1 || true
        /bin/rm -rf "$WORK_DIR"
        /usr/bin/open -a "$INSTALL_APP"
        /bin/rm -f "$0"
        """

        do {
            try script.write(to: scriptURL, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = [scriptURL.path]
            try process.run()
        } catch {
            let alert = NSAlert(error: error)
            alert.runModal()
        }
    }

    private func shellQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    @objc private func uninstall(_ sender: Any?) {
        let alert = NSAlert()
        alert.messageText = AppStrings.uninstallTitle
        alert.informativeText = AppStrings.uninstallMessage
        alert.alertStyle = .warning
        alert.addButton(withTitle: AppStrings.uninstallConfirm)
        alert.addButton(withTitle: AppStrings.cancel)

        guard alert.runModal() == .alertFirstButtonReturn else {
            return
        }

        launchUninstaller()
        NSApp.terminate(nil)
    }

    @objc private func selectRefreshMode(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let mode = RefreshMode(rawValue: rawValue) else {
            return
        }

        RefreshMode.current = mode
        updateRefreshModeMenuState()
        scheduleNextRefresh()
    }

    @objc private func selectMenuBarDisplayMode(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let mode = MenuBarDisplayMode(rawValue: rawValue) else {
            return
        }

        MenuBarDisplayMode.current = mode
        updateMenuBarDisplayModeMenuState()
        updateStatusButton()
    }

    @objc private func selectMenuBarTextColor(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String else {
            return
        }

        let parts = rawValue.split(separator: "|", maxSplits: 1).map(String.init)
        guard parts.count == 2,
              let group = MenuBarTextGroup(rawValue: parts[0]),
              let color = MenuBarTextColor(rawValue: parts[1]) else {
            return
        }

        group.currentColor = color
        updateMenuBarTextColorMenuState()
        updateStatusButton()
    }

    private func launchUninstaller() {
        let scriptURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("uninstall-codexvisual-\(UUID().uuidString).sh")
        let script = """
        #!/bin/zsh
        /bin/sleep 1
        /usr/bin/pkill -x "CodexVisual" 2>/dev/null || true
        /usr/bin/pkill -x "CodexQuotaBar" 2>/dev/null || true
        /bin/rm -rf "$HOME/Applications/CodexVisual.app"
        /bin/rm -rf "$HOME/Applications/CodexQuotaBar.app"
        /bin/rm -rf "$HOME/Applications/Codex Visual.app"
        /bin/rm -rf "$HOME/Library/Application Support/CodexVisual"
        /bin/rm -rf "$HOME/Library/Application Support/CodexQuotaBar"
        /bin/rm -rf "$HOME/Library/Caches/com.orangeshushu.CodexVisual"
        /bin/rm -rf "$HOME/Library/Caches/CodexVisual"
        /bin/rm -f "$HOME/Library/Preferences/com.orangeshushu.CodexVisual.plist"
        /bin/rm -rf "$HOME/Library/HTTPStorages/com.orangeshushu.CodexVisual"
        /bin/rm -rf "$HOME/Library/WebKit/com.orangeshushu.CodexVisual"
        /bin/rm -rf "$HOME/Library/Containers/com.orangeshushu.CodexVisual"
        /bin/rm -rf "/Applications/CodexVisual.app" 2>/dev/null || true
        /bin/rm -rf "/Applications/CodexQuotaBar.app" 2>/dev/null || true
        /bin/rm -rf "/Applications/Codex Visual.app" 2>/dev/null || true
        /usr/bin/osascript -e 'display notification "\(AppStrings.uninstallDone)" with title "CodexVisual"' 2>/dev/null || true
        /bin/rm -f "$0"
        """

        do {
            try script.write(to: scriptURL, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = [scriptURL.path]
            try process.run()
        } catch {
            let alert = NSAlert(error: error)
            alert.runModal()
        }
    }

    private func update(_ snapshot: QuotaSnapshot) {
        latestSnapshot = snapshot
        updateStaticMenuText()
        guard let weekly = snapshot.event.rateLimits.weekly else {
            return
        }
        updateStatusButton()
        statusItem.button?.toolTip = AppStrings.quotaToolTip(weekly: weekly.remainingPercent)

        let plan = snapshot.event.planType?.uppercased() ?? AppStrings.unknown
        for item in quotaDetailItems {
            item.isHidden = false
        }
        overviewView.update(
            snapshot: snapshot,
            plan: plan,
            timeFormatter: timeFormatter,
            shortTimeFormatter: shortTimeFormatter
        )
        updateWindow(snapshot)
        errorItem.isHidden = true
    }

    private func updateStatusButton() {
        guard let button = statusItem.button else {
            return
        }

        guard let snapshot = latestSnapshot else {
            statusItem.length = NSStatusItem.variableLength
            button.image = nil
            button.imagePosition = .noImage
            button.title = AppStrings.statusTitlePlaceholder
            return
        }

        guard let weekly = snapshot.event.rateLimits.weekly else {
            return
        }

        switch MenuBarDisplayMode.current {
        case .bars:
            statusItem.length = 176
            button.title = ""
            button.imagePosition = .imageOnly
            button.imageScaling = .scaleProportionallyDown
            button.image = nil
            button.effectiveAppearance.performAsCurrentDrawingAppearance {
                button.image = QuotaStatusImage.make(
                    weekly: weekly.remainingPercent,
                    weeklyReset: weekly.resetDate
                )
            }
            button.needsDisplay = true
        case .numbers:
            statusItem.length = NSStatusItem.variableLength
            button.image = nil
            button.imagePosition = .noImage
            button.title = "Codex \(weekly.remainingPercent)%"
        }
    }

    private func updateWindow(_ snapshot: QuotaSnapshot) {
        windowOverviewView.isHidden = false
        windowErrorLabel.isHidden = true
        let plan = snapshot.event.planType?.uppercased() ?? AppStrings.unknown
        windowOverviewView.update(
            snapshot: snapshot,
            plan: plan,
            timeFormatter: timeFormatter,
            shortTimeFormatter: shortTimeFormatter
        )
    }

    private func updateWindow(error: String) {
        windowOverviewView.isHidden = true
        windowErrorLabel.isHidden = false
        windowErrorLabel.stringValue = error
    }

    @objc private func selectSystemLanguage(_ sender: Any?) {
        setLanguageMode(.system)
    }

    @objc private func selectEnglishLanguage(_ sender: Any?) {
        setLanguageMode(.english)
    }

    @objc private func selectChineseLanguage(_ sender: Any?) {
        setLanguageMode(.chinese)
    }

    private func setLanguageMode(_ mode: LanguageMode) {
        LanguageMode.current = mode
        updateLanguageMenuState()
        updateStaticMenuText()
        updateRefreshModeMenuState()

        if let snapshot = latestSnapshot {
            update(snapshot)
        } else {
            refresh(nil)
        }
    }

    @objc private func quit(_ sender: Any?) {
        NSApp.terminate(nil)
    }
}

if CommandLine.arguments.contains("--diagnostics") {
    print(QuotaReader().diagnostics())
} else if CommandLine.arguments.contains("--print") {
    do {
        let snapshot = try QuotaReader().readLatest()
        guard let weekly = snapshot.event.rateLimits.weekly else {
            throw QuotaReadError.missingEvent
        }
        print("weekly_remaining=\(weekly.remainingPercent)")
        print("weekly_reset=\(weekly.resetDate)")
        print("source=\(snapshot.source.title)")
    } catch {
        fputs("\(error.localizedDescription)\n", stderr)
        exit(1)
    }
} else {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}
