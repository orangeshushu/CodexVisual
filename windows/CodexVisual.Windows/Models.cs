using System;
using System.Text.Json.Serialization;

namespace CodexVisual.Windows;

internal sealed class RateLimitEvent
{
    [JsonPropertyName("type")]
    public string Type { get; set; } = "";

    [JsonPropertyName("plan_type")]
    public string? PlanType { get; set; }

    [JsonPropertyName("rate_limits")]
    public RateLimits RateLimits { get; set; } = new();
}

internal sealed class RateLimits
{
    [JsonPropertyName("limit_id")]
    public string? LimitId { get; set; }

    [JsonPropertyName("limit_name")]
    public string? LimitName { get; set; }

    [JsonPropertyName("allowed")]
    public bool Allowed { get; set; }

    [JsonPropertyName("limit_reached")]
    public bool LimitReached { get; set; }

    [JsonPropertyName("primary")]
    public QuotaWindow? Primary { get; set; }

    [JsonPropertyName("secondary")]
    public QuotaWindow? Secondary { get; set; }

    [JsonIgnore]
    public QuotaWindow? Weekly
    {
        get
        {
            var primary = Primary;
            var secondary = Secondary;
            if (primary is null)
            {
                return secondary;
            }

            if (secondary is null)
            {
                return primary;
            }

            return primary.WindowMinutes >= secondary.WindowMinutes ? primary : secondary;
        }
    }
}

internal sealed class QuotaWindow
{
    [JsonPropertyName("used_percent")]
    public int UsedPercent { get; set; }

    [JsonPropertyName("window_minutes")]
    public int WindowMinutes { get; set; }

    [JsonPropertyName("reset_after_seconds")]
    public int? ResetAfterSeconds { get; set; }

    [JsonPropertyName("reset_at")]
    public double ResetAt { get; set; }

    public DateTimeOffset ResetDate => DateTimeOffset.FromUnixTimeMilliseconds((long)(ResetAt * 1000));

    public int EffectiveUsedPercent => ResetDate <= DateTimeOffset.Now ? 0 : Math.Clamp(UsedPercent, 0, 100);

    public int RemainingPercent => Math.Clamp(100 - EffectiveUsedPercent, 0, 100);

    public int LastKnownRemainingPercent => Math.Clamp(100 - Math.Clamp(UsedPercent, 0, 100), 0, 100);
}

internal sealed record QuotaSnapshot(
    RateLimitEvent Event,
    DateTimeOffset LogDate,
    DateTimeOffset ReadDate,
    string Source,
    string SourcePath);

internal sealed record LogSchema(
    string TimestampColumn,
    string? TimestampNanosColumn,
    string? IdColumn,
    string BodyColumn);

internal sealed record SQLiteColumn(string Name, string Type);

internal sealed class SessionLogEntry
{
    [JsonPropertyName("timestamp")]
    public string Timestamp { get; set; } = "";

    [JsonPropertyName("payload")]
    public SessionPayload Payload { get; set; } = new();
}

internal sealed class SessionPayload
{
    [JsonPropertyName("type")]
    public string? Type { get; set; }

    [JsonPropertyName("rate_limits")]
    public SessionRateLimits? RateLimits { get; set; }
}

internal sealed class SessionRateLimits
{
    [JsonPropertyName("limit_id")]
    public string? LimitId { get; set; }

    [JsonPropertyName("limit_name")]
    public string? LimitName { get; set; }

    [JsonPropertyName("plan_type")]
    public string? PlanType { get; set; }

    [JsonPropertyName("primary")]
    public SessionQuotaWindow? Primary { get; set; }

    [JsonPropertyName("secondary")]
    public SessionQuotaWindow? Secondary { get; set; }

    [JsonPropertyName("rate_limit_reached_type")]
    public string? RateLimitReachedType { get; set; }
}

internal sealed class SessionQuotaWindow
{
    [JsonPropertyName("used_percent")]
    public double UsedPercent { get; set; }

    [JsonPropertyName("window_minutes")]
    public int WindowMinutes { get; set; }

    [JsonPropertyName("resets_at")]
    public double ResetsAt { get; set; }
}
