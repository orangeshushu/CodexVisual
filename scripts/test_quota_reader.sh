#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_BINARY="$ROOT_DIR/build/CodexVisual.app/Contents/MacOS/CodexVisual"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/codexvisual-quota-test.XXXXXX")"
export CODEX_VISUAL_CACHE_DIR="$TEST_DIR/cache"

cleanup() {
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT

if [[ ! -x "$APP_BINARY" ]]; then
  "$ROOT_DIR/scripts/build_app.sh" >/dev/null
fi

mkdir -p "$TEST_DIR/latest-events" "$TEST_DIR/zero-primary" "$TEST_DIR/plus-dual" "$TEST_DIR/pro-dual"

cat > "$TEST_DIR/latest-events/newer-primary.jsonl" <<'JSON'
{"type":"session_meta","payload":{"source":"cli"}}
{"timestamp":"2099-01-02T00:00:00.000Z","payload":{"type":"token_count","rate_limits":{"limit_id":"codex","primary":{"used_percent":42.0,"window_minutes":10080,"resets_at":4102444800},"secondary":null,"plan_type":"pro","rate_limit_reached_type":null}}}
JSON

cat > "$TEST_DIR/latest-events/newer-file-with-model-limit.jsonl" <<'JSON'
{"type":"session_meta","payload":{"source":"cli"}}
{"timestamp":"2099-01-01T00:00:00.000Z","payload":{"type":"token_count","rate_limits":{"limit_id":"codex","primary":{"used_percent":10.0,"window_minutes":10080,"resets_at":4102444800},"secondary":null,"plan_type":"pro","rate_limit_reached_type":null}}}
{"timestamp":"2099-01-03T00:00:00.000Z","payload":{"type":"token_count","rate_limits":{"limit_id":"codex_bengalfox","primary":{"used_percent":25.0,"window_minutes":10080,"resets_at":4102444800},"secondary":null,"plan_type":"pro","rate_limit_reached_type":null}}}
JSON

cat > "$TEST_DIR/zero-primary/reset-primary.jsonl" <<'JSON'
{"type":"session_meta","payload":{"source":"cli"}}
{"timestamp":"2099-01-04T00:00:00.000Z","payload":{"type":"token_count","rate_limits":{"limit_id":"codex","primary":{"used_percent":0.0,"window_minutes":10080,"resets_at":4102444800},"secondary":null,"plan_type":"pro","rate_limit_reached_type":null}}}
JSON

cat > "$TEST_DIR/plus-dual/plus-quota.jsonl" <<'JSON'
{"type":"session_meta","payload":{"source":"cli"}}
{"timestamp":"2099-01-05T00:00:00.000Z","payload":{"type":"token_count","rate_limits":{"limit_id":"codex","primary":{"used_percent":21.0,"window_minutes":300,"resets_at":4102444800},"secondary":{"used_percent":37.0,"window_minutes":10080,"resets_at":4102444800},"plan_type":"plus","rate_limit_reached_type":null}}}
JSON

cat > "$TEST_DIR/pro-dual/pro-quota.jsonl" <<'JSON'
{"type":"session_meta","payload":{"source":"cli"}}
{"timestamp":"2099-01-06T00:00:00.000Z","payload":{"type":"token_count","rate_limits":{"limit_id":"codex","primary":{"used_percent":21.0,"window_minutes":300,"resets_at":4102444800},"secondary":{"used_percent":37.0,"window_minutes":10080,"resets_at":4102444800},"plan_type":"pro","rate_limit_reached_type":null}}}
JSON

touch -t 210001010000 "$TEST_DIR/latest-events/newer-primary.jsonl"
touch -t 210001010001 "$TEST_DIR/latest-events/newer-file-with-model-limit.jsonl"

latest_output="$({
  CODEX_VISUAL_DISABLE_APP_SERVER=1 \
  CODEX_VISUAL_SESSIONS_DIR="$TEST_DIR/latest-events" \
  CODEX_VISUAL_LOG_DB="$TEST_DIR/missing.sqlite" \
  "$APP_BINARY" --print
})"

zero_output="$({
  CODEX_VISUAL_DISABLE_APP_SERVER=1 \
  CODEX_VISUAL_SESSIONS_DIR="$TEST_DIR/zero-primary" \
  CODEX_VISUAL_LOG_DB="$TEST_DIR/missing.sqlite" \
  "$APP_BINARY" --print
})"

plus_output="$({
  CODEX_VISUAL_DISABLE_APP_SERVER=1 \
  CODEX_VISUAL_SESSIONS_DIR="$TEST_DIR/plus-dual" \
  CODEX_VISUAL_LOG_DB="$TEST_DIR/missing.sqlite" \
  "$APP_BINARY" --print
})"

pro_output="$({
  CODEX_VISUAL_DISABLE_APP_SERVER=1 \
  CODEX_VISUAL_SESSIONS_DIR="$TEST_DIR/pro-dual" \
  CODEX_VISUAL_LOG_DB="$TEST_DIR/missing.sqlite" \
  "$APP_BINARY" --print
})"

cat > "$TEST_DIR/account-response.json" <<'JSON'
{"id":2,"result":{"rateLimits":{"limitId":"codex","planType":"pro","primary":{"usedPercent":4,"windowDurationMins":10080,"resetsAt":4102444800},"secondary":null},"rateLimitsByLimitId":{"codex":{"limitId":"codex","planType":"pro","primary":{"usedPercent":4,"windowDurationMins":10080,"resetsAt":4102444800},"secondary":null}}}}
JSON

account_output="$({
  CODEX_VISUAL_ACCOUNT_RESPONSE_FILE="$TEST_DIR/account-response.json" \
  CODEX_VISUAL_SESSIONS_DIR="$TEST_DIR/latest-events" \
  CODEX_VISUAL_LOG_DB="$TEST_DIR/missing.sqlite" \
  "$APP_BINARY" --print
})"

if ! rg -q '^weekly_remaining=58$' <<< "$latest_output"; then
  echo "Expected newest primary Codex quota to report 58% remaining." >&2
  echo "$latest_output" >&2
  exit 1
fi

if ! rg -q '^weekly_remaining=100$' <<< "$zero_output"; then
  echo "Expected a freshly reset primary Codex quota to report 100% remaining." >&2
  echo "$zero_output" >&2
  exit 1
fi

if ! rg -q '^weekly_remaining=96$' <<< "$account_output"; then
  echo "Expected the current Codex account response to override stale session data." >&2
  echo "$account_output" >&2
  exit 1
fi

if ! rg -q '^source=(Codex account|当前账号)$' <<< "$account_output"; then
  echo "Expected the authoritative account source to be reported." >&2
  echo "$account_output" >&2
  exit 1
fi

if ! rg -q '^historical=false$' <<< "$account_output" ||
   ! rg -q '^historical=true$' <<< "$plus_output" ||
   ! rg -q '^data_updated=2099-01-05T00:00:00Z$' <<< "$plus_output"; then
  echo "Expected log fallbacks to preserve the quota event timestamp and historical label." >&2
  exit 1
fi

if ! rg -q '^weekly_remaining=63$' <<< "$plus_output" ||
   ! rg -q '^five_hour_visible=true$' <<< "$plus_output" ||
   ! rg -q '^five_hour_remaining=79$' <<< "$plus_output"; then
  echo "Expected Plus to expose both the five-hour and weekly quotas." >&2
  echo "$plus_output" >&2
  exit 1
fi

if ! rg -q '^weekly_remaining=63$' <<< "$pro_output" ||
   ! rg -q '^five_hour_visible=false$' <<< "$pro_output" ||
   rg -q '^five_hour_remaining=' <<< "$pro_output"; then
  echo "Expected Pro to keep the weekly-only display even when a five-hour window is present." >&2
  echo "$pro_output" >&2
  exit 1
fi

cat > "$TEST_DIR/dual-account.json" <<'JSON'
{"id":2,"result":{"rateLimits":{"limitId":"codex","planType":"plus","primary":{"usedPercent":21,"windowDurationMins":300,"resetsAt":4102444800},"secondary":{"usedPercent":37,"windowDurationMins":10080,"resetsAt":4102531200}},"rateLimitsByLimitId":{"codex":{"limitId":"codex","planType":"plus","primary":{"usedPercent":21,"windowDurationMins":300,"resetsAt":4102444800},"secondary":{"usedPercent":37,"windowDurationMins":10080,"resetsAt":4102531200}}}}}
JSON

check_account() {
  local fixture="$1" expected_five_hour="$2"
  local output
  output="$(CODEX_VISUAL_ACCOUNT_RESPONSE_FILE="$fixture" \
    CODEX_VISUAL_SESSIONS_DIR="$TEST_DIR/latest-events" \
    CODEX_VISUAL_LOG_DB="$TEST_DIR/missing.sqlite" "$APP_BINARY" --print)"
  if ! rg -q '^weekly_remaining=63$' <<< "$output" ||
     ! rg -q "^five_hour_visible=$expected_five_hour$" <<< "$output" ||
     ! rg -q '^source=(Codex account|当前账号)$' <<< "$output"; then
    echo "Unexpected account window selection for $fixture: $output" >&2
    exit 1
  fi
  if [[ "$expected_five_hour" == true ]] &&
     { ! rg -q '^five_hour_remaining=79$' <<< "$output" ||
       ! rg -q '^five_hour_reset=2100-01-01 00:00:00 \+0000$' <<< "$output"; }; then
    echo "Five-hour percentage or reset came from the wrong window: $output" >&2
    exit 1
  fi
}

check_account "$TEST_DIR/dual-account.json" true
jq '.result.rateLimitsByLimitId.codex.planType = null' "$TEST_DIR/dual-account.json" > "$TEST_DIR/missing-bucket-plan.json"
check_account "$TEST_DIR/missing-bucket-plan.json" true
jq '.result.rateLimits.planType = " CHATGPT_PRO " | .result.rateLimitsByLimitId.codex.planType = null' "$TEST_DIR/dual-account.json" > "$TEST_DIR/legacy-pro-plan.json"
check_account "$TEST_DIR/legacy-pro-plan.json" false
jq '.result.rateLimits.planType = null | .result.rateLimitsByLimitId.codex.planType = null' "$TEST_DIR/dual-account.json" > "$TEST_DIR/no-plan.json"
check_account "$TEST_DIR/no-plan.json" true
jq '.result.rateLimitsByLimitId.codex |= (.primary as $short | .primary = .secondary | .secondary = $short)' "$TEST_DIR/dual-account.json" > "$TEST_DIR/reversed-windows.json"
check_account "$TEST_DIR/reversed-windows.json" true
jq '.result.rateLimitsByLimitId.codex.primary = null' "$TEST_DIR/dual-account.json" > "$TEST_DIR/weekly-only-plus.json"
check_account "$TEST_DIR/weekly-only-plus.json" false

for transform in '.result.rateLimitsByLimitId.codex.secondary = null' \
                 '.result.rateLimitsByLimitId.codex.secondary.windowDurationMins = 1440' \
                 '.result.rateLimitsByLimitId.codex.secondary.windowDurationMins = null'; do
  jq "$transform" "$TEST_DIR/dual-account.json" > "$TEST_DIR/not-weekly.json"
  rejected_output="$(CODEX_VISUAL_CACHE_DIR="$TEST_DIR/rejected-cache" \
    CODEX_VISUAL_ACCOUNT_RESPONSE_FILE="$TEST_DIR/not-weekly.json" \
    CODEX_VISUAL_SESSIONS_DIR="$TEST_DIR/latest-events" \
    CODEX_VISUAL_LOG_DB="$TEST_DIR/missing.sqlite" "$APP_BINARY" --print)"
  if ! rg -q '^weekly_remaining=58$' <<< "$rejected_output"; then
    echo "A short, daily, or unknown-duration window was incorrectly treated as weekly: $rejected_output" >&2
    exit 1
  fi
done

echo "Quota reader integration tests passed."
