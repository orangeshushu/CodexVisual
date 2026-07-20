param(
    [Parameter(Mandatory = $false)]
    [string]$ExecutablePath = ".\build\windows\CodexVisual.Windows\CodexVisual.Windows.exe"
)

$ErrorActionPreference = "Stop"
$executable = (Resolve-Path -LiteralPath $ExecutablePath).Path
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ("codexvisual-quota-test-" + [Guid]::NewGuid().ToString("N"))
$sessions = Join-Path $testRoot "sessions"

try {
    New-Item -ItemType Directory -Path $sessions -Force | Out-Null

    @'
{"type":"session_meta","payload":{"source":"cli"}}
{"timestamp":"2099-01-02T00:00:00.000Z","payload":{"type":"token_count","rate_limits":{"limit_id":"codex","limit_name":null,"primary":{"used_percent":9.0,"window_minutes":10080,"resets_at":4102444800},"secondary":null,"plan_type":"pro","rate_limit_reached_type":null}}}
'@ | Set-Content -LiteralPath (Join-Path $sessions "account-quota.jsonl") -Encoding utf8

    @'
{"type":"session_meta","payload":{"source":"cli"}}
{"timestamp":"2099-01-01T00:00:00.000Z","payload":{"type":"token_count","rate_limits":{"limit_id":"codex","limit_name":null,"primary":{"used_percent":12.0,"window_minutes":10080,"resets_at":4102444800},"secondary":null,"plan_type":"pro","rate_limit_reached_type":null}}}
{"timestamp":"2099-01-03T00:00:00.000Z","payload":{"type":"token_count","rate_limits":{"limit_id":"codex_bengalfox","limit_name":"GPT-5.3-Codex-Spark","primary":{"used_percent":0.0,"window_minutes":10080,"resets_at":4102444800},"secondary":null,"plan_type":"pro","rate_limit_reached_type":null}}}
'@ | Set-Content -LiteralPath (Join-Path $sessions "newer-model-quota.jsonl") -Encoding utf8

    $env:CODEX_VISUAL_SESSIONS_DIR = $sessions
    $env:CODEX_VISUAL_LOG_DB = Join-Path $testRoot "missing.sqlite"
    $output = & $executable --diagnostics | Out-String

    if ($output -notmatch '(?m)^Latest session weekly quota: 91%\r?$') {
        throw ("Expected the account-wide weekly quota to report 91% remaining. Diagnostics:" + [Environment]::NewLine + $output)
    }

    Write-Host "Windows quota reader integration test passed."
}
finally {
    Remove-Item Env:CODEX_VISUAL_SESSIONS_DIR -ErrorAction SilentlyContinue
    Remove-Item Env:CODEX_VISUAL_LOG_DB -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
}
