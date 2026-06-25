import AppKit
import Foundation

enum AppStrings {
    static var usesChinese: Bool {
        let language = ProcessInfo.processInfo.environment["CODEX_VISUAL_LANGUAGE"]
            ?? preferredAppleLanguage
            ?? Locale.preferredLanguages.first
            ?? "en"
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
    static var unknown: String { text("未知", "Unknown") }
    static var codexLogs: String { text("Codex 日志", "Codex logs") }
    static var localCache: String { text("本地缓存", "local cache") }
    static var migratedCache: String { text("旧版缓存", "legacy cache") }

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
    let source: String
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
    private let databasePath: String

    init(databasePath: String = NSHomeDirectory() + "/.codex/logs_2.sqlite") {
        self.databasePath = databasePath
    }

    func readLatest() throws -> QuotaSnapshot {
        if let liveSnapshot = try readFromLogs() {
            saveCache(snapshot: liveSnapshot)
            return liveSnapshot
        }

        if let cachedSnapshot = readCache() {
            return cachedSnapshot
        }

        throw QuotaReadError.missingEvent
    }

    private func readFromLogs() throws -> QuotaSnapshot? {
        guard FileManager.default.fileExists(atPath: databasePath) else {
            throw QuotaReadError.missingDatabase(databasePath)
        }

        let query = """
        select ts, feedback_log_body
        from logs
        where instr(feedback_log_body, 'Received message {"type":"codex.rate_limits"') = 1
        order by ts desc, ts_nanos desc, id desc
        limit 50;
        """

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
                    source: AppStrings.codexLogs
                )
            }
        }

        return nil
    }

    private func extractRateLimitEvent(from body: String) -> RateLimitEvent? {
        let needles = ["{\"type\":\"codex.rate_limits\"", "{\\\"type\\\":\\\"codex.rate_limits\\\""]

        for needle in needles {
            var searchStart = body.startIndex
            while let range = body.range(of: needle, range: searchStart..<body.endIndex) {
                let rawCandidate = String(body[range.lowerBound...])
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
        readCache(at: cacheURL, source: AppStrings.localCache)
            ?? readCache(at: legacyCacheURL, source: AppStrings.migratedCache)
    }

    private func readCache(at url: URL, source: String) -> QuotaSnapshot? {
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

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let reader = QuotaReader()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private let fiveHourItem = NSMenuItem()
    private let fiveHourResetItem = NSMenuItem()
    private let sevenDayItem = NSMenuItem()
    private let sevenDayResetItem = NSMenuItem()
    private let orderItem = NSMenuItem()
    private let planItem = NSMenuItem()
    private let logTimeItem = NSMenuItem()
    private let readTimeItem = NSMenuItem()
    private let errorItem = NSMenuItem()
    private var timer: Timer?

    private var quotaDetailItems: [NSMenuItem] {
        [planItem, fiveHourItem, fiveHourResetItem, sevenDayItem, sevenDayResetItem, logTimeItem, readTimeItem]
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
        statusItem.button?.toolTip = AppStrings.statusToolTip
        orderItem.title = AppStrings.displayOrder
        errorItem.isHidden = true

        for item in [orderItem, planItem, fiveHourItem, fiveHourResetItem, sevenDayItem, sevenDayResetItem, logTimeItem, readTimeItem, errorItem] {
            item.isEnabled = false
            item.title = item.title.isEmpty ? " " : item.title
            item.isHidden = quotaDetailItems.contains(item)
            menu.addItem(item)
        }

        menu.addItem(.separator())
        let refreshItem = NSMenuItem(title: AppStrings.refreshNow, action: #selector(refresh(_:)), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: AppStrings.quit, action: #selector(quit(_:)), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func refresh(_ sender: Any?) {
        do {
            let snapshot = try reader.readLatest()
            update(snapshot)
        } catch {
            statusItem.button?.title = AppStrings.statusTitlePlaceholder
            statusItem.button?.toolTip = error.localizedDescription
            orderItem.title = AppStrings.displayOrder
            for item in quotaDetailItems {
                item.isHidden = true
            }
            errorItem.title = error.localizedDescription
            errorItem.isHidden = false
        }
    }

    private func update(_ snapshot: QuotaSnapshot) {
        let primary = snapshot.event.rateLimits.primary
        let secondary = snapshot.event.rateLimits.secondary
        let title = "Codex \(primary.remainingPercent) / \(secondary.remainingPercent)%"
        statusItem.button?.title = title
        statusItem.button?.toolTip = AppStrings.quotaToolTip(
            fiveHour: primary.remainingPercent,
            sevenDay: secondary.remainingPercent
        )

        let plan = snapshot.event.planType?.uppercased() ?? AppStrings.unknown
        orderItem.title = AppStrings.displayOrder
        for item in quotaDetailItems {
            item.isHidden = false
        }
        planItem.title = AppStrings.plan(plan)
        fiveHourItem.title = AppStrings.fiveHourRemaining(
            remaining: primary.remainingPercent,
            used: primary.usedPercent
        )
        fiveHourResetItem.title = AppStrings.fiveHourReset(timeFormatter.string(from: primary.resetDate))
        sevenDayItem.title = AppStrings.sevenDayRemaining(
            remaining: secondary.remainingPercent,
            used: secondary.usedPercent
        )
        sevenDayResetItem.title = AppStrings.sevenDayReset(timeFormatter.string(from: secondary.resetDate))
        logTimeItem.title = AppStrings.dataSource(
            source: snapshot.source,
            time: timeFormatter.string(from: snapshot.logDate)
        )
        readTimeItem.title = AppStrings.lastRead(shortTimeFormatter.string(from: snapshot.readDate))
        errorItem.isHidden = true
    }

    @objc private func quit(_ sender: Any?) {
        NSApp.terminate(nil)
    }
}

if CommandLine.arguments.contains("--print") {
    do {
        let snapshot = try QuotaReader().readLatest()
        let primary = snapshot.event.rateLimits.primary
        let secondary = snapshot.event.rateLimits.secondary
        print("5h_remaining=\(primary.remainingPercent)")
        print("7d_remaining=\(secondary.remainingPercent)")
        print("5h_reset=\(primary.resetDate)")
        print("7d_reset=\(secondary.resetDate)")
        print("source=\(snapshot.source)")
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
