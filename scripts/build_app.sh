#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/build/CodexVisual.app"
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:--}"
ENTITLEMENTS_PATH="${ENTITLEMENTS_PATH:-$ROOT_DIR/Resources/CodexVisual.entitlements}"

cd "$ROOT_DIR"
mkdir -p "$ROOT_DIR/.build/clang-module-cache"
export CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.build/clang-module-cache"

swift build \
  --disable-sandbox \
  --cache-path "$ROOT_DIR/.build/swiftpm-cache" \
  --config-path "$ROOT_DIR/.build/swiftpm-config" \
  --scratch-path "$ROOT_DIR/.build" \
  --manifest-cache local \
  -c release \
  --product CodexVisual

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$ROOT_DIR/.build/release/CodexVisual" "$APP_DIR/Contents/MacOS/CodexVisual"
cp "$ROOT_DIR/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"

if [[ "$CODE_SIGN_IDENTITY" == "-" ]]; then
  /usr/bin/codesign --force --sign - "$APP_DIR" >/dev/null
else
  /usr/bin/codesign \
    --force \
    --sign "$CODE_SIGN_IDENTITY" \
    --options runtime \
    --timestamp \
    --entitlements "$ENTITLEMENTS_PATH" \
    "$APP_DIR" >/dev/null

  /usr/bin/codesign --verify --deep --strict --verbose=2 "$APP_DIR" >/dev/null
fi

echo "$APP_DIR"
