#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
DMG_ROOT="$BUILD_DIR/app-dmg-root"
DMG_PATH="$BUILD_DIR/CodexVisual.dmg"

if [[ -z "${CODE_SIGN_IDENTITY:-}" || "$CODE_SIGN_IDENTITY" == "-" ]]; then
  echo "A Developer ID Application identity is required." >&2
  exit 1
fi

"$ROOT_DIR/scripts/build_app.sh"
rm -rf "$DMG_ROOT"
mkdir -p "$DMG_ROOT"
ditto "$BUILD_DIR/CodexVisual.app" "$DMG_ROOT/CodexVisual.app"
ln -s /Applications "$DMG_ROOT/Applications"
cp "$ROOT_DIR/scripts/uninstall.sh" "$DMG_ROOT/Uninstall CodexVisual.command"
chmod +x "$DMG_ROOT/Uninstall CodexVisual.command"
cp "$ROOT_DIR/Resources/Usage Guide.txt" "$DMG_ROOT/Usage Guide.txt"
hdiutil create -volname CodexVisual -srcfolder "$DMG_ROOT" -ov -fs HFS+ -format UDZO "$DMG_PATH"
keychain_args=()
if [[ -n "${CODE_SIGN_KEYCHAIN:-}" ]]; then
  keychain_args=(--keychain "$CODE_SIGN_KEYCHAIN")
fi
codesign --force --sign "$CODE_SIGN_IDENTITY" ${keychain_args[@]+"${keychain_args[@]}"} --timestamp "$DMG_PATH"
codesign --verify --verbose=2 "$DMG_PATH"
echo "$DMG_PATH"
