#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_BINARY="$ROOT_DIR/build/CodexVisual.app/Contents/MacOS/CodexVisual"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/codexvisual-quota-test.XXXXXX")"

cleanup() {
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT

if [[ ! -x "$APP_BINARY" ]]; then
  "$ROOT_DIR/scripts/build_app.sh" >/dev/null
fi

mkdir -p "$TEST_DIR/latest-events" "$TEST_DIR/zero-primary"

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

if ! rg -q '^source=Codex (account|当前账号)$' <<< "$account_output"; then
  echo "Expected the authoritative account source to be reported." >&2
  echo "$account_output" >&2
  exit 1
fi

echo "Quota reader integration tests passed."
