#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/build/CodexVisual.app"

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

/usr/bin/codesign --force --sign - "$APP_DIR" >/dev/null

echo "$APP_DIR"
