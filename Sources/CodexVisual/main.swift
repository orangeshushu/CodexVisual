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
        text("\(value) 刷新", "resets \(value)")
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
        let exactEventClause = "feedback_log_body like '%Received message {\"type\":\"codex.rate_limits\"%'"
        if let snapshot = try readFromLogs(databasePath: databasePath, whereClause: exactEventClause, limit: 2000) {
            return snapshot
        }

        let broadEventClause = "feedback_log_body like '%codex.rate_limits%'"
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
            if let event = extractRateLimitEvent(from: body) {
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

    private func configure() {
        wantsLayer = true
        layer?.cornerRadius = 8
        layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.10).cgColor

        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        nameLabel.textColor = .labelColor

        percentLabel.font = .monospacedDigitSystemFont(ofSize: 28, weight: .bold)
        percentLabel.textColor = .labelColor
        percentLabel.alignment = .right
        percentLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        suffixLabel.font = .systemFont(ofSize: 12, weight: .medium)
        suffixLabel.textColor = .secondaryLabelColor

        detailLabel.font = .systemFont(ofSize: 12, weight: .regular)
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.lineBreakMode = .byTruncatingTail

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
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
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

    private func configure() {
        frame.size = NSSize(width: 532, height: 202)

        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .labelColor

        planLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
        planLabel.textColor = .secondaryLabelColor
        planLabel.alignment = .right

        sourceLabel.font = .systemFont(ofSize: 12, weight: .regular)
        sourceLabel.textColor = .secondaryLabelColor
        sourceLabel.lineBreakMode = .byTruncatingTail

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
            fiveHourView.heightAnchor.constraint(equalToConstant: 66),
            sevenDayView.heightAnchor.constraint(equalToConstant: 66),
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
            resetText: timeFormatter.string(from: primary.resetDate)
        )
        sevenDayView.update(
            name: AppStrings.sevenDayQuota,
            remaining: secondary.remainingPercent,
            used: secondary.usedPercent,
            resetText: timeFormatter.string(from: secondary.resetDate)
        )
        sourceLabel.stringValue = AppStrings.sourceCompact(
            source: snapshot.source.title,
            readTime: shortTimeFormatter.string(from: snapshot.readDate)
        )
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
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
    private let diagnosticsItem = NSMenuItem()
    private let refreshItem = NSMenuItem()
    private let quitItem = NSMenuItem()
    private var timer: Timer?
    private var latestSnapshot: QuotaSnapshot?

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
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh(nil)
            }
        }
    }

    private func configureMenu() {
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

        menu.addItem(.separator())
        diagnosticsItem.action = #selector(copyDiagnostics(_:))
        diagnosticsItem.target = self
        menu.addItem(diagnosticsItem)

        refreshItem.action = #selector(refresh(_:))
        refreshItem.keyEquivalent = "r"
        refreshItem.target = self
        menu.addItem(refreshItem)

        menu.addItem(.separator())
        quitItem.action = #selector(quit(_:))
        quitItem.keyEquivalent = "q"
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        updateStaticMenuText()
        updateLanguageMenuState()
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
        diagnosticsItem.title = AppStrings.copyDiagnostics
        refreshItem.title = AppStrings.refreshNow
        quitItem.title = AppStrings.quit
    }

    private func updateLanguageMenuState() {
        let currentMode = LanguageMode.current
        systemLanguageItem.state = currentMode == .system ? .on : .off
        englishLanguageItem.state = currentMode == .english ? .on : .off
        chineseLanguageItem.state = currentMode == .chinese ? .on : .off
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
        }
    }

    @objc private func copyDiagnostics(_ sender: Any?) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(reader.diagnostics(), forType: .string)
        diagnosticsItem.title = AppStrings.diagnosticsCopied
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.diagnosticsItem.title = AppStrings.copyDiagnostics
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
        errorItem.isHidden = true
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
