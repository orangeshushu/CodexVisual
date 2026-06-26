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
            UserDefaults.standard.set(newValue.rawValue, forKey: defaultsKey)
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
        usesChinese ? "M月d日 HH:mm" : "MMM d HH:mm"
    }

    static var shortTimeFormat: String {
        "HH:mm:ss"
    }

    static let statusTitlePlaceholder = "Codex -- / --%"
    static var statusToolTip: String { text("Codex 额度", "Codex quota") }
    static var displayOrder: String { text("显示顺序: 5小时 / 7天", "Display order: 5-hour / 7-day") }
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
    static var codexLogs: String { text("Codex 日志", "Codex logs") }
    static var localCache: String { text("本地缓存", "local cache") }
    static var migratedCache: String { text("旧版缓存", "legacy cache") }
    static var copyDiagnostics: String { text("复制诊断信息", "Copy Diagnostics") }
    static var diagnosticsCopied: String { text("诊断信息已复制", "Diagnostics copied") }
    static var quotaOverview: String { text("Codex 额度", "Codex Quota") }
    static var controlWindowTitle: String { text("CodexVisual 控制窗口", "CodexVisual Control Window") }
    static var noQuotaYet: String { text("还没有读取到 Codex 额度。请打开 Codex 并发送一条消息，然后点击刷新。", "No Codex quota has been read yet. Open Codex, send one message, then click Refresh.") }
    static var fiveHourQuota: String { text("5 小时", "5-hour") }
    static var sevenDayQuota: String { text("7 天", "7-day") }
    static var remaining: String { text("剩余", "remaining") }

    static func missingDatabase(_ path: String) -> String {
        text("未找到 Codex 日志数据库: \(path)", "Codex log database not found: \(path)")
    }

    static func sqliteFailed(_ message: String) -> String {
        text("读取 SQLite 失败: \(message)", "Failed to read SQLite: \(message)")
    }

    static var missingEvent: String {
        text("还没有读到 codex.rate_limits 事件", "No codex.rate_limits event has been found yet")
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

    static func quotaToolTip(fiveHour: Int, sevenDay: Int) -> String {
        text("5小时 / 7天: \(fiveHour)% / \(sevenDay)%",
             "5-hour / 7-day: \(fiveHour)% / \(sevenDay)%")
    }

    static func plan(_ value: String) -> String {
        text("计划: \(value)", "Plan: \(value)")
    }

    static func fiveHourRemaining(remaining: Int, used: Int) -> String {
        text("5小时剩余: \(remaining)% (已用 \(used)%)",
             "5-hour remaining: \(remaining)% (used \(used)%)")
    }

    static func fiveHourReset(_ value: String) -> String {
        text("5小时刷新: \(value)", "5-hour reset: \(value)")
    }

    static func sevenDayRemaining(remaining: Int, used: Int) -> String {
        text("7天剩余: \(remaining)% (已用 \(used)%)",
             "7-day remaining: \(remaining)% (used \(used)%)")
    }

    static func sevenDayReset(_ value: String) -> String {
        text("7天刷新: \(value)", "7-day reset: \(value)")
    }

    static func dataSource(source: String, time: String) -> String {
        text("数据来源: \(source), \(time)", "Data source: \(source), \(time)")
    }

    static func lastRead(_ value: String) -> String {
        text("最后读取: \(value)", "Last read: \(value)")
    }

    static func usedCompact(_ value: Int) -> String {
        text("已用 \(value)%", "used \(value)%")
    }

    static func resetCompact(_ value: String) -> String {
        text("下次刷新: \(value)", "next reset: \(value)")
    }

    static func sourceCompact(source: String, readTime: String) -> String {
        text("来源: \(source) · 读取: \(readTime)", "Source: \(source) · Read: \(readTime)")
    }
}

enum SnapshotSource {
    case codexLogs
    case localCache
    case migratedCache

    var title: String {
        switch self {
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
    let primary: QuotaWindow
    let secondary: QuotaWindow

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
        min(100, max(0, 100 - usedPercent))
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

    init(databasePaths: [String]? = nil) {
        if let override = ProcessInfo.processInfo.environment["CODEX_VISUAL_LOG_DB"],
           !override.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.databasePaths = [override]
        } else if let databasePaths {
            self.databasePaths = databasePaths
        } else {
            let home = NSHomeDirectory()
            self.databasePaths = [
                home + "/.codex/logs_2.sqlite",
                home + "/.codex/sqlite/logs_2.sqlite"
            ]
        }
    }

    func readLatest() throws -> QuotaSnapshot {
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

        if let cachedSnapshot = readCache() {
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

    private func readFromLogs(databasePath: String) throws -> QuotaSnapshot? {
        let exactEventClause = "instr(feedback_log_body, 'Received message {\"type\":\"codex.rate_limits\"') = 1"
        if let snapshot = try readFromLogs(databasePath: databasePath, whereClause: exactEventClause, limit: 2000) {
            return snapshot
        }

        let broadEventClause = """
        feedback_log_body like '%codex.rate_limits%'
        and length(feedback_log_body) < 20000
        and feedback_log_body not like '%function_call_arguments%'
        and feedback_log_body not like '%exec_command%'
        """
        return try readFromLogs(databasePath: databasePath, whereClause: broadEventClause, limit: 200)
    }

    private func readFromLogs(databasePath: String, whereClause: String, limit: Int) throws -> QuotaSnapshot? {
        let query = """
        with candidates as (
            select
                ts,
                feedback_log_body,
                instr(feedback_log_body, 'codex.rate_limits') as match_pos
            from logs
            where \(whereClause)
            order by ts desc, ts_nanos desc, id desc
            limit \(limit)
        )
        select
            ts,
            substr(
                feedback_log_body,
                case when match_pos > 128 then match_pos - 128 else 1 end,
                100000
            )
        from candidates
        ;
        """

        let output = try runSQLite(databasePath: databasePath, query: query)

        for line in output.split(separator: "\n", omittingEmptySubsequences: true) {
            let parts = line.split(separator: "\t", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2, let timestamp = TimeInterval(parts[0]) else {
                continue
            }

            let body = String(parts[1])
            if let event = extractRateLimitEvent(from: body), isCurrentRateLimitEvent(event) {
                return QuotaSnapshot(
                    event: event,
                    logDate: Date(timeIntervalSince1970: timestamp),
                    readDate: Date(),
                    source: .codexLogs
                )
            }
        }

        return nil
    }

    private func isCurrentRateLimitEvent(_ event: RateLimitEvent) -> Bool {
        let now = Date()
        return event.rateLimits.primary.resetDate > now || event.rateLimits.secondary.resetDate > now
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
            "Checked databases:"
        ]

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

            if let candidates = try? runSQLite(
                databasePath: databasePath,
                query: "select count(*) from logs where feedback_log_body like '%codex.rate_limits%';"
            ).trimmingCharacters(in: .whitespacesAndNewlines) {
                lines.append("  codex.rate_limits candidates: \(candidates)")
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
                event: snapshot.event,
                logTimestamp: snapshot.logDate.timeIntervalSince1970,
                cachedTimestamp: Date().timeIntervalSince1970
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
            return QuotaSnapshot(
                event: cached.event,
                logDate: Date(timeIntervalSince1970: cached.logTimestamp),
                readDate: Date(timeIntervalSince1970: cached.cachedTimestamp),
                source: source
            )
        } catch {
            return nil
        }
    }
}

struct CachedSnapshot: Codable {
    let event: RateLimitEvent
    let logTimestamp: TimeInterval
    let cachedTimestamp: TimeInterval
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

final class QuotaWindowView: NSView {
    private let nameLabel = NSTextField(labelWithString: "")
    private let percentLabel = NSTextField(labelWithString: "")
    private let suffixLabel = NSTextField(labelWithString: "")
    private let detailLabel = NSTextField(labelWithString: "")
    private let progress = NSProgressIndicator()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: 86)
    }

    private func configure() {
        wantsLayer = true
        layer?.cornerRadius = 8
        layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.10).cgColor

        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = .labelColor

        percentLabel.font = .monospacedDigitSystemFont(ofSize: 30, weight: .bold)
        percentLabel.textColor = .labelColor
        percentLabel.alignment = .right
        percentLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        suffixLabel.font = .systemFont(ofSize: 12, weight: .medium)
        suffixLabel.textColor = .secondaryLabelColor

        detailLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.lineBreakMode = .byTruncatingTail
        detailLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        progress.style = .bar
        progress.isIndeterminate = false
        progress.minValue = 0
        progress.maxValue = 100
        progress.controlSize = .small

        let percentStack = NSStackView(views: [percentLabel, suffixLabel])
        percentStack.orientation = .horizontal
        percentStack.alignment = .firstBaseline
        percentStack.spacing = 6

        let topStack = NSStackView(views: [nameLabel, NSView(), percentStack])
        topStack.orientation = .horizontal
        topStack.alignment = .centerY
        topStack.spacing = 8

        let stack = NSStackView(views: [topStack, progress, detailLabel])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            progress.widthAnchor.constraint(equalTo: stack.widthAnchor),
            progress.heightAnchor.constraint(equalToConstant: 6)
        ])
    }

    func update(name: String, remaining: Int, used: Int, resetText: String) {
        nameLabel.stringValue = name
        percentLabel.stringValue = "\(remaining)%"
        suffixLabel.stringValue = AppStrings.remaining
        detailLabel.stringValue = "\(AppStrings.usedCompact(used)) · \(AppStrings.resetCompact(resetText))"
        progress.doubleValue = Double(remaining)

        if remaining <= 20 {
            layer?.backgroundColor = NSColor.systemRed.withAlphaComponent(0.12).cgColor
        } else if remaining <= 50 {
            layer?.backgroundColor = NSColor.systemOrange.withAlphaComponent(0.12).cgColor
        } else {
            layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.10).cgColor
        }
    }
}

final class QuotaOverviewView: NSView {
    private let titleLabel = NSTextField(labelWithString: "")
    private let planLabel = NSTextField(labelWithString: "")
    private let fiveHourView = QuotaWindowView()
    private let sevenDayView = QuotaWindowView()
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
        NSSize(width: 532, height: 268)
    }

    private func configure() {
        frame.size = intrinsicContentSize

        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .labelColor

        planLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
        planLabel.textColor = .secondaryLabelColor
        planLabel.alignment = .right

        sourceLabel.font = .systemFont(ofSize: 11, weight: .regular)
        sourceLabel.textColor = .secondaryLabelColor
        sourceLabel.lineBreakMode = .byTruncatingTail
        sourceLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        let header = NSStackView(views: [titleLabel, NSView(), planLabel])
        header.orientation = .horizontal
        header.alignment = .centerY
        header.spacing = 10

        let stack = NSStackView(views: [header, fiveHourView, sevenDayView, sourceLabel])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            header.widthAnchor.constraint(equalTo: stack.widthAnchor),
            fiveHourView.widthAnchor.constraint(equalTo: stack.widthAnchor),
            sevenDayView.widthAnchor.constraint(equalTo: stack.widthAnchor),
            fiveHourView.heightAnchor.constraint(equalToConstant: 86),
            sevenDayView.heightAnchor.constraint(equalToConstant: 86),
            sourceLabel.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
    }

    func update(snapshot: QuotaSnapshot, plan: String, timeFormatter: DateFormatter, shortTimeFormatter: DateFormatter) {
        let primary = snapshot.event.rateLimits.primary
        let secondary = snapshot.event.rateLimits.secondary

        titleLabel.stringValue = AppStrings.quotaOverview
        planLabel.stringValue = AppStrings.plan(plan)
        fiveHourView.update(
            name: AppStrings.fiveHourQuota,
            remaining: primary.remainingPercent,
            used: primary.usedPercent,
            resetText: resetText(for: primary.resetDate, timeFormatter: timeFormatter)
        )
        sevenDayView.update(
            name: AppStrings.sevenDayQuota,
            remaining: secondary.remainingPercent,
            used: secondary.usedPercent,
            resetText: resetText(for: secondary.resetDate, timeFormatter: timeFormatter)
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

        return timeFormatter.string(from: date)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let reader = QuotaReader()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private let overviewItem = NSMenuItem()
    private let overviewView = QuotaOverviewView()
    private let fiveHourItem = NSMenuItem()
    private let fiveHourResetItem = NSMenuItem()
    private let sevenDayItem = NSMenuItem()
    private let sevenDayResetItem = NSMenuItem()
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
    private let diagnosticsItem = NSMenuItem()
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
    private let windowDiagnosticsButton = NSButton()
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

        menu.addItem(.separator())
        openDashboardItem.action = #selector(openDashboard(_:))
        openDashboardItem.target = self
        menu.addItem(openDashboardItem)

        diagnosticsItem.action = #selector(copyDiagnostics(_:))
        diagnosticsItem.target = self
        menu.addItem(diagnosticsItem)

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
    }

    private func configureStatusButton() {
        guard let button = statusItem.button else {
            return
        }

        button.image = nil
        button.imagePosition = .noImage

        button.target = self
        button.action = #selector(showMenu(_:))
        button.sendAction(on: [.leftMouseDown, .rightMouseDown])
    }

    @objc private func showMenu(_ sender: Any?) {
        guard let button = statusItem.button else {
            return
        }

        button.highlight(true)
        statusItem.popUpMenu(menu)
        button.highlight(false)
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

    private func updateDateFormatters() {
        timeFormatter.locale = AppStrings.dateLocale
        timeFormatter.dateFormat = AppStrings.dateFormat
        shortTimeFormatter.locale = AppStrings.dateLocale
        shortTimeFormatter.dateFormat = AppStrings.shortTimeFormat
    }

    private func updateStaticMenuText() {
        updateDateFormatters()
        statusItem.button?.toolTip = latestSnapshot.map {
            AppStrings.quotaToolTip(
                fiveHour: $0.event.rateLimits.primary.remainingPercent,
                sevenDay: $0.event.rateLimits.secondary.remainingPercent
            )
        } ?? AppStrings.statusToolTip
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
        openDashboardItem.title = AppStrings.openDashboard
        diagnosticsItem.title = AppStrings.copyDiagnostics
        refreshItem.title = AppStrings.refreshNow
        checkUpdatesItem.title = AppStrings.checkForUpdates
        uninstallItem.title = AppStrings.uninstall
        quitItem.title = AppStrings.quit
        windowRefreshButton.title = AppStrings.refreshNow
        windowDiagnosticsButton.title = AppStrings.copyDiagnostics
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

    @objc private func refresh(_ sender: Any?) {
        do {
            let snapshot = try reader.readLatest()
            update(snapshot)
        } catch {
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
            let resetDates = [
                snapshot.event.rateLimits.primary.resetDate,
                snapshot.event.rateLimits.secondary.resetDate
            ]

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
        configureWindowButton(windowDiagnosticsButton, action: #selector(copyDiagnostics(_:)))
        configureWindowButton(windowUpdateButton, action: #selector(checkForUpdates(_:)))
        configureWindowButton(windowUninstallButton, action: #selector(uninstall(_:)))
        configureWindowButton(windowQuitButton, action: #selector(quit(_:)))

        let buttonStack = NSStackView(views: [
            windowRefreshButton,
            windowDiagnosticsButton,
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
            windowOverviewView.widthAnchor.constraint(equalToConstant: 532),
            windowErrorLabel.widthAnchor.constraint(equalToConstant: 532),
            windowErrorLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 80),
            buttonStack.widthAnchor.constraint(equalToConstant: 532)
        ])

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 568, height: 360),
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

    @objc private func copyDiagnostics(_ sender: Any?) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(reader.diagnostics(), forType: .string)
        diagnosticsItem.title = AppStrings.diagnosticsCopied
        windowDiagnosticsButton.title = AppStrings.diagnosticsCopied
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.diagnosticsItem.title = AppStrings.copyDiagnostics
            self?.windowDiagnosticsButton.title = AppStrings.copyDiagnostics
        }
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
        if [[ -w "/Applications" ]]; then
          /bin/rm -rf "/Applications/CodexVisual.app"
          /bin/rm -rf "/Applications/CodexQuotaBar.app"
          /bin/rm -rf "/Applications/Codex Visual.app"
        fi
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
        let primary = snapshot.event.rateLimits.primary
        let secondary = snapshot.event.rateLimits.secondary
        let title = "Codex \(primary.remainingPercent) / \(secondary.remainingPercent)%"
        statusItem.button?.title = title
        statusItem.button?.toolTip = AppStrings.quotaToolTip(
            fiveHour: primary.remainingPercent,
            sevenDay: secondary.remainingPercent
        )

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
        let primary = snapshot.event.rateLimits.primary
        let secondary = snapshot.event.rateLimits.secondary
        print("5h_remaining=\(primary.remainingPercent)")
        print("7d_remaining=\(secondary.remainingPercent)")
        print("5h_reset=\(primary.resetDate)")
        print("7d_reset=\(secondary.resetDate)")
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
