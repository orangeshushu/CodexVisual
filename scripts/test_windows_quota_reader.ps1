param(
    [Parameter(Mandatory = $false)]
    [string]$ExecutablePath = ".\build\windows\CodexVisual.Windows\CodexVisual.Windows.exe"
)

$ErrorActionPreference = "Stop"
$executable = (Resolve-Path -LiteralPath $ExecutablePath).Path
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ("codexvisual-quota-test-" + [Guid]::NewGuid().ToString("N"))
$sessions = Join-Path $testRoot "sessions"
$proSessions = Join-Path $testRoot "pro-sessions"

try {
    New-Item -ItemType Directory -Path $sessions -Force | Out-Null
    New-Item -ItemType Directory -Path $proSessions -Force | Out-Null

    @'
{"type":"session_meta","payload":{"source":"cli"}}
{"timestamp":"2099-01-02T00:00:00.000Z","payload":{"type":"token_count","rate_limits":{"limit_id":"codex","limit_name":null,"primary":{"used_percent":9.0,"window_minutes":300,"resets_at":4102444800},"secondary":{"used_percent":20.0,"window_minutes":10080,"resets_at":4102444800},"plan_type":"plus","rate_limit_reached_type":null}}}
'@ | Set-Content -LiteralPath (Join-Path $sessions "account-quota.jsonl") -Encoding utf8

    @'
{"type":"session_meta","payload":{"source":"cli"}}
{"timestamp":"2099-01-01T00:00:00.000Z","payload":{"type":"token_count","rate_limits":{"limit_id":"codex","limit_name":null,"primary":{"used_percent":12.0,"window_minutes":10080,"resets_at":4102444800},"secondary":null,"plan_type":"pro","rate_limit_reached_type":null}}}
{"timestamp":"2099-01-03T00:00:00.000Z","payload":{"type":"token_count","rate_limits":{"limit_id":"codex_bengalfox","limit_name":"GPT-5.3-Codex-Spark","primary":{"used_percent":0.0,"window_minutes":10080,"resets_at":4102444800},"secondary":null,"plan_type":"pro","rate_limit_reached_type":null}}}
'@ | Set-Content -LiteralPath (Join-Path $sessions "newer-model-quota.jsonl") -Encoding utf8

    @'
{"type":"session_meta","payload":{"source":"cli"}}
{"timestamp":"2099-01-04T00:00:00.000Z","payload":{"type":"token_count","rate_limits":{"limit_id":"codex","limit_name":null,"primary":{"used_percent":9.0,"window_minutes":300,"resets_at":4102444800},"secondary":{"used_percent":20.0,"window_minutes":10080,"resets_at":4102444800},"plan_type":"pro","rate_limit_reached_type":null}}}
'@ | Set-Content -LiteralPath (Join-Path $proSessions "pro-quota.jsonl") -Encoding utf8

    $env:CODEX_VISUAL_SESSIONS_DIR = $sessions
    $env:CODEX_VISUAL_LOG_DB = Join-Path $testRoot "missing.sqlite"
    $output = & $executable --diagnostics | Out-String

    if ($output -notmatch '(?m)^Latest session weekly quota: 80%\r?$' -or
        $output -notmatch '(?m)^Latest session five-hour visible: True\r?$' -or
        $output -notmatch '(?m)^Latest session five-hour quota: 91%\r?$') {
        throw ("Expected Plus to expose both the five-hour and weekly quotas. Diagnostics:" + [Environment]::NewLine + $output)
    }

    $env:CODEX_VISUAL_SESSIONS_DIR = $proSessions
    $proOutput = & $executable --diagnostics | Out-String
    if ($proOutput -notmatch '(?m)^Latest session weekly quota: 80%\r?$' -or
        $proOutput -notmatch '(?m)^Latest session five-hour visible: False\r?$' -or
        $proOutput -match '(?m)^Latest session five-hour quota:') {
        throw ("Expected Pro to keep the weekly-only display. Diagnostics:" + [Environment]::NewLine + $proOutput)
    }

    Write-Host "Windows quota reader integration test passed."
}
finally {
    Remove-Item Env:CODEX_VISUAL_SESSIONS_DIR -ErrorAction SilentlyContinue
    Remove-Item Env:CODEX_VISUAL_LOG_DB -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
}
