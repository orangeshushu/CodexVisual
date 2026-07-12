using Microsoft.Data.Sqlite;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.Json;

namespace CodexVisual.Windows;

internal sealed class QuotaReader
{
    private readonly string[] _databasePaths;
    private readonly string _sessionsDirectory;
    private readonly DateTimeOffset _minimumEventDate;
    private QuotaSnapshot? _latestExpiredSnapshot;
    private static readonly JsonSerializerOptions JsonOptions = new() { PropertyNameCaseInsensitive = true };

    public QuotaReader(string[]? databasePaths = null, DateTimeOffset? minimumEventDate = null)
    {
        var home = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
        _minimumEventDate = minimumEventDate ?? DateTimeOffset.Now.AddSeconds(-5);
        var sessionsOverride = Environment.GetEnvironmentVariable("CODEX_VISUAL_SESSIONS_DIR");
        _sessionsDirectory = !string.IsNullOrWhiteSpace(sessionsOverride)
            ? sessionsOverride
            : Path.Combine(home, ".codex", "sessions");

        var overridePath = Environment.GetEnvironmentVariable("CODEX_VISUAL_LOG_DB");
        if (!string.IsNullOrWhiteSpace(overridePath))
        {
            _databasePaths = [overridePath];
            return;
        }

        _databasePaths = databasePaths ?? [
            Path.Combine(home, ".codex", "logs_2.sqlite"),
            Path.Combine(home, ".codex", "sqlite", "logs_2.sqlite"),
            Path.Combine(home, ".codex", "logs.sqlite"),
            Path.Combine(home, ".codex", "sqlite", "logs.sqlite")
        ];
    }

    public QuotaSnapshot ReadLatest(bool includeExistingEvents = false)
    {
        var existingDatabaseSeen = false;
        var sessionsSeen = Directory.Exists(_sessionsDirectory);
        var sqliteErrors = new List<string>();
        _latestExpiredSnapshot = null;

        if (ReadFromSessions(includeExistingEvents) is { } sessionSnapshot)
        {
            return sessionSnapshot;
        }

        foreach (var databasePath in _databasePaths)
        {
            if (!File.Exists(databasePath))
            {
                continue;
            }

            existingDatabaseSeen = true;

            try
            {
                var snapshot = ReadFromLogs(databasePath, includeExistingEvents);
                if (snapshot is not null)
                {
                    return snapshot;
                }
            }
            catch (SqliteException ex)
            {
                sqliteErrors.Add($"{databasePath}: {ex.Message}");
            }
            catch (IOException ex)
            {
                sqliteErrors.Add($"{databasePath}: {ex.Message}");
            }
        }

        if (sqliteErrors.Count > 0)
        {
            throw new QuotaReadException(AppText.SqliteFailed(string.Join(Environment.NewLine, sqliteErrors)));
        }

        if (!existingDatabaseSeen)
        {
            if (sessionsSeen)
            {
                throw new QuotaReadException(AppText.MissingEvent);
            }

            throw new QuotaReadException(AppText.MissingDatabase(string.Join(", ", _databasePaths)));
        }

        if (_latestExpiredSnapshot is not null)
        {
            var latestReset = _latestExpiredSnapshot.Event.RateLimits.Weekly!.ResetDate;
            throw new QuotaExpiredException(AppText.MissingExpiredEvent(latestReset), _latestExpiredSnapshot);
        }

        throw new QuotaReadException(AppText.MissingEvent);
    }

    public string Diagnostics()
    {
        var lines = new List<string>
        {
            "CodexVisual Windows diagnostics",
            $"Home: {Environment.GetFolderPath(Environment.SpecialFolder.UserProfile)}",
            $"Minimum event date: {_minimumEventDate.LocalDateTime:yyyy-MM-dd HH:mm:ss}",
            $"Sessions: {_sessionsDirectory}",
            $"Sessions exists: {Directory.Exists(_sessionsDirectory)}",
            "Checked databases:"
        };

        if (ReadFromSessions(includeExistingEvents: true) is { } sessionSnapshot)
        {
            lines.Add($"Latest session weekly quota: {sessionSnapshot.Event.RateLimits.Weekly!.RemainingPercent}%");
            lines.Add($"Latest session quota read date: {sessionSnapshot.LogDate}");
        }

        foreach (var databasePath in _databasePaths)
        {
            lines.Add($"- {databasePath}");
            lines.Add($"  exists: {File.Exists(databasePath)}");
            if (!File.Exists(databasePath))
            {
                continue;
            }

            var file = new FileInfo(databasePath);
            lines.Add($"  size: {file.Length} bytes");
            lines.Add($"  modified: {file.LastWriteTime}");

            try
            {
                using var connection = OpenConnection(databasePath);
                using var countCommand = connection.CreateCommand();
                countCommand.CommandText = "select count(*) from logs;";
                lines.Add($"  log rows: {countCommand.ExecuteScalar()}");

                var schema = LoadLogSchema(connection);
                if (schema is not null)
                {
                    lines.Add($"  detected timestamp column: {schema.TimestampColumn}");
                    lines.Add($"  detected body column: {schema.BodyColumn}");
                    using var candidatesCommand = connection.CreateCommand();
                    candidatesCommand.CommandText = $"select count(*) from logs where {QuoteIdentifier(schema.BodyColumn)} like '%codex.rate_limits%';";
                    lines.Add($"  codex.rate_limits candidates: {candidatesCommand.ExecuteScalar()}");
                }
            }
            catch (Exception ex)
            {
                lines.Add($"  error: {ex.Message}");
            }
        }

        return string.Join(Environment.NewLine, lines);
    }

    private QuotaSnapshot? ReadFromSessions(bool includeExistingEvents)
    {
        if (!Directory.Exists(_sessionsDirectory))
        {
            return null;
        }

        var cutoff = DateTimeOffset.Now.AddDays(-14);
        var files = Directory.EnumerateFiles(_sessionsDirectory, "*.jsonl", SearchOption.AllDirectories)
            .Select(path => new FileInfo(path))
            .Where(file => file.Exists && file.LastWriteTime >= cutoff.LocalDateTime)
            .OrderByDescending(file => file.LastWriteTime)
            .Take(120)
            .ToArray();

        return files
            .Select(ReadFromSessionFile)
            .Where(snapshot => snapshot is not null && (includeExistingEvents || snapshot.LogDate >= _minimumEventDate))
            .Select(snapshot => snapshot!)
            .OrderByDescending(snapshot => snapshot.LogDate)
            .FirstOrDefault();
    }

    private QuotaSnapshot? ReadFromSessionFile(FileInfo file)
    {
        const long maxTailBytes = 4 * 1024 * 1024;
        string text;

        try
        {
            using var stream = File.Open(file.FullName, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete);
            if (stream.Length > maxTailBytes)
            {
                stream.Seek(stream.Length - maxTailBytes, SeekOrigin.Begin);
            }

            using var reader = new StreamReader(stream, Encoding.UTF8, detectEncodingFromByteOrderMarks: true);
            text = reader.ReadToEnd();
        }
        catch
        {
            return null;
        }

        if (file.Length > maxTailBytes)
        {
            var firstNewline = text.IndexOf('\n');
            if (firstNewline >= 0)
            {
                text = text[(firstNewline + 1)..];
            }
        }

        var lines = text.Split('\n', StringSplitOptions.RemoveEmptyEntries);
        for (var i = lines.Length - 1; i >= 0; i--)
        {
            var line = lines[i];
            if (!line.Contains("\"rate_limits\"", StringComparison.Ordinal) ||
                !line.Contains("\"token_count\"", StringComparison.Ordinal))
            {
                continue;
            }

            var snapshot = DecodeSessionRateLimitLine(line);
            if (snapshot is not null && IsCurrentRateLimitEvent(snapshot.Event) && IsUsefulSessionSnapshot(snapshot))
            {
                return snapshot;
            }
        }

        return null;
    }

    private static QuotaSnapshot? DecodeSessionRateLimitLine(string line)
    {
        try
        {
            var entry = JsonSerializer.Deserialize<SessionLogEntry>(line, JsonOptions);
            var rateLimits = entry?.Payload.RateLimits;
            if (entry?.Payload.Type != "token_count" || rateLimits is null ||
                (rateLimits.Primary is null && rateLimits.Secondary is null))
            {
                return null;
            }

            var primary = rateLimits.Primary is null ? null : QuotaWindowFromSession(rateLimits.Primary);
            var secondary = rateLimits.Secondary is null ? null : QuotaWindowFromSession(rateLimits.Secondary);
            var rateLimitEvent = new RateLimitEvent
            {
                Type = "codex.rate_limits",
                PlanType = rateLimits.PlanType,
                RateLimits = new RateLimits
                {
                    Allowed = true,
                    LimitReached = rateLimits.RateLimitReachedType is not null,
                    Primary = primary,
                    Secondary = secondary
                }
            };

            return new QuotaSnapshot(
                rateLimitEvent,
                ParseSessionTimestamp(entry.Timestamp) ?? DateTimeOffset.Now,
                DateTimeOffset.Now,
                AppText.CodexSessions,
                "");
        }
        catch (JsonException)
        {
            return null;
        }
    }

    private static QuotaWindow QuotaWindowFromSession(SessionQuotaWindow window)
    {
        return new QuotaWindow
        {
            UsedPercent = Math.Clamp((int)Math.Ceiling(window.UsedPercent), 0, 100),
            WindowMinutes = window.WindowMinutes,
            ResetAfterSeconds = Math.Max(0, (int)(window.ResetsAt - DateTimeOffset.Now.ToUnixTimeSeconds())),
            ResetAt = window.ResetsAt
        };
    }

    private static bool IsUsefulSessionSnapshot(QuotaSnapshot snapshot)
    {
        return snapshot.Event.RateLimits.Weekly is not null;
    }

    private static DateTimeOffset? ParseSessionTimestamp(string value)
    {
        if (DateTimeOffset.TryParse(value, CultureInfo.InvariantCulture, DateTimeStyles.AssumeUniversal, out var parsed))
        {
            return parsed;
        }

        return null;
    }

    private QuotaSnapshot? ReadFromLogs(string databasePath, bool includeExistingEvents)
    {
        using var connection = OpenConnection(databasePath);
        var schema = LoadLogSchema(connection);
        if (schema is null)
        {
            return null;
        }

        var body = QuoteIdentifier(schema.BodyColumn);
        var whereClause = $$"""
        (
          {{body}} like '%websocket event: {"type":"codex.rate_limits"%'
          or {{body}} like '%Received message {"type":"codex.rate_limits"%'
          or {{body}} like '%websocket event: {\"type\":\"codex.rate_limits\"%'
          or {{body}} like '%Received message {\"type\":\"codex.rate_limits\"%'
        )
        and {{body}} not like '%exec_command%'
        and {{body}} not like '%tool exec_command%'
        and {{body}} not like '%*** Begin Patch%'
        and {{body}} not like '%Sources/CodexVisual%'
        and {{body}} not like '%CodexVisual.Windows%'
        """;

        return ReadFromLogs(connection, databasePath, schema, whereClause, limit: 100, recentOnly: true, includeExistingEvents)
            ?? ReadFromLogs(connection, databasePath, schema, whereClause, limit: 100, recentOnly: false, includeExistingEvents);
    }

    private QuotaSnapshot? ReadFromLogs(SqliteConnection connection, string databasePath, LogSchema schema, string whereClause, int limit, bool recentOnly, bool includeExistingEvents)
    {
        var ts = QuoteIdentifier(schema.TimestampColumn);
        var body = QuoteIdentifier(schema.BodyColumn);
        var id = QuoteIdentifier(schema.IdColumn ?? "rowid");
        var orderColumns = new[] { schema.TimestampColumn, schema.TimestampNanosColumn, schema.IdColumn }
            .Where(column => !string.IsNullOrWhiteSpace(column))
            .Select(column => $"{QuoteIdentifier(column!)} desc")
            .ToArray();
        var orderBy = orderColumns.Length == 0 ? $"{ts} desc" : string.Join(", ", orderColumns);

        using var command = connection.CreateCommand();
        var recentFilter = "";
        if (recentOnly)
        {
            var recentLimit = Math.Max(limit * 200, 50_000);
            recentFilter = $"""
              and {id} in (
                select {id}
                from logs
                order by {orderBy}
                limit {recentLimit}
              )
            """;
        }

        command.CommandText = $"""
        select
            {ts},
            substr(
                {body},
                case when instr({body}, 'codex.rate_limits') > 128 then instr({body}, 'codex.rate_limits') - 128 else 1 end,
                100000
            )
        from logs
        where {whereClause}
        {recentFilter}
        order by {orderBy}
        limit {limit};
        """;

        using var reader = command.ExecuteReader();
        while (reader.Read())
        {
            if (reader.IsDBNull(0) || reader.IsDBNull(1))
            {
                continue;
            }

            var timestamp = Convert.ToDouble(reader.GetValue(0), CultureInfo.InvariantCulture);
            var text = reader.GetString(1);
            var rateLimitEvent = ExtractRateLimitEvent(text);
            if (rateLimitEvent is null)
            {
                continue;
            }

            var snapshot = new QuotaSnapshot(
                rateLimitEvent,
                DateFromDatabaseTimestamp(timestamp),
                DateTimeOffset.Now,
                AppText.CodexLogs,
                databasePath);
            if (!includeExistingEvents && snapshot.LogDate < _minimumEventDate)
            {
                continue;
            }

            if (IsCurrentRateLimitEvent(rateLimitEvent))
            {
                return snapshot;
            }

            if (_latestExpiredSnapshot is null || snapshot.LogDate > _latestExpiredSnapshot.LogDate)
            {
                _latestExpiredSnapshot = snapshot;
            }
        }

        return null;
    }

    private static SqliteConnection OpenConnection(string databasePath)
    {
        var builder = new SqliteConnectionStringBuilder
        {
            DataSource = databasePath,
            Mode = SqliteOpenMode.ReadOnly,
            Cache = SqliteCacheMode.Private
        };

        var connection = new SqliteConnection(builder.ToString());
        connection.Open();
        return connection;
    }

    private static LogSchema? LoadLogSchema(SqliteConnection connection)
    {
        using var command = connection.CreateCommand();
        command.CommandText = "pragma table_info(logs);";
        using var reader = command.ExecuteReader();

        var columns = new List<SQLiteColumn>();
        while (reader.Read())
        {
            columns.Add(new SQLiteColumn(reader.GetString(1), reader.GetString(2)));
        }

        if (columns.Count == 0)
        {
            return null;
        }

        var names = columns.Select(column => column.Name).ToArray();
        var timestampColumn = FirstExisting(names, ["ts", "timestamp", "created_at", "time", "date"]) ?? "ts";
        var nanosColumn = FirstExisting(names, ["ts_nanos", "timestamp_nanos", "nanos"]);
        var idColumn = FirstExisting(names, ["id", "rowid"]);
        var bodyColumn = FirstExisting(names, ["feedback_log_body", "body", "message", "text", "payload", "event", "json"])
            ?? columns.FirstOrDefault(column =>
                column.Type.Contains("text", StringComparison.OrdinalIgnoreCase) &&
                new[] { "body", "message", "payload", "event", "json", "log" }
                    .Any(part => column.Name.Contains(part, StringComparison.OrdinalIgnoreCase)))?.Name;

        if (!names.Contains(timestampColumn) || bodyColumn is null || !names.Contains(bodyColumn))
        {
            return null;
        }

        return new LogSchema(timestampColumn, nanosColumn, idColumn, bodyColumn);
    }

    private static string? FirstExisting(string[] names, string[] candidates)
    {
        foreach (var candidate in candidates)
        {
            var match = names.FirstOrDefault(name => string.Equals(name, candidate, StringComparison.OrdinalIgnoreCase));
            if (match is not null)
            {
                return match;
            }
        }

        return null;
    }

    private static string QuoteIdentifier(string value) => "\"" + value.Replace("\"", "\"\"", StringComparison.Ordinal) + "\"";

    private static DateTimeOffset DateFromDatabaseTimestamp(double timestamp)
    {
        if (timestamp > 10_000_000_000)
        {
            timestamp /= 1000;
        }

        return DateTimeOffset.FromUnixTimeMilliseconds((long)(timestamp * 1000));
    }

    private static bool IsCurrentRateLimitEvent(RateLimitEvent rateLimitEvent)
    {
        return rateLimitEvent.RateLimits.Weekly?.ResetDate > DateTimeOffset.Now;
    }

    private static RateLimitEvent? ExtractRateLimitEvent(string body)
    {
        string[] needles = ["{\"type\":\"codex.rate_limits\"", "{\\\"type\\\":\\\"codex.rate_limits\\\""];

        foreach (var needle in needles)
        {
            var searchStart = 0;
            while (searchStart < body.Length)
            {
                var index = body.IndexOf(needle, searchStart, StringComparison.Ordinal);
                if (index < 0)
                {
                    break;
                }

                var length = Math.Min(100_000, body.Length - index);
                var candidate = body.Substring(index, length);
                if (needle.Contains("\\\"", StringComparison.Ordinal))
                {
                    candidate = candidate
                        .Replace("\\\"", "\"", StringComparison.Ordinal)
                        .Replace("\\\\", "\\", StringComparison.Ordinal);
                }

                var rateLimitEvent = DecodeJsonPrefix(candidate);
                if (rateLimitEvent?.Type == "codex.rate_limits")
                {
                    return rateLimitEvent;
                }

                searchStart = index + 1;
            }
        }

        return null;
    }

    private static RateLimitEvent? DecodeJsonPrefix(string text)
    {
        var depth = 0;
        var inString = false;
        var escaped = false;

        for (var i = 0; i < text.Length; i++)
        {
            var character = text[i];
            if (inString)
            {
                if (escaped)
                {
                    escaped = false;
                }
                else if (character == '\\')
                {
                    escaped = true;
                }
                else if (character == '"')
                {
                    inString = false;
                }

                continue;
            }

            if (character == '"')
            {
                inString = true;
            }
            else if (character == '{')
            {
                depth++;
            }
            else if (character == '}')
            {
                depth--;
                if (depth == 0)
                {
                    var json = text[..(i + 1)];
                    try
                    {
                        return JsonSerializer.Deserialize<RateLimitEvent>(json, JsonOptions);
                    }
                    catch (JsonException)
                    {
                        return null;
                    }
                }
            }
        }

        return null;
    }
}

internal class QuotaReadException(string message) : Exception(message);

internal sealed class QuotaExpiredException(string message, QuotaSnapshot snapshot) : QuotaReadException(message)
{
    public QuotaSnapshot Snapshot { get; } = snapshot;
}
