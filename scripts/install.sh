#!/usr/bin/env bash
set -euo pipefail

APP_NAME="CodexVisual"
EXECUTABLE_NAME="CodexVisual"
OLD_EXECUTABLE_NAME="CodexQuotaBar"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INSTALL_DIR="$HOME/Applications"
INSTALL_APP="$INSTALL_DIR/$APP_NAME.app"
OLD_INSTALL_APP="$INSTALL_DIR/CodexQuotaBar.app"
SPACED_INSTALL_APP="$INSTALL_DIR/Codex Visual.app"

if [[ -d "$(dirname "$0")/$APP_NAME.app" ]]; then
  SOURCE_APP="$(dirname "$0")/$APP_NAME.app"
elif [[ -d "$ROOT_DIR/build/$APP_NAME.app" ]]; then
  SOURCE_APP="$ROOT_DIR/build/$APP_NAME.app"
else
  "$ROOT_DIR/scripts/build_app.sh" >/dev/null
  SOURCE_APP="$ROOT_DIR/build/$APP_NAME.app"
fi

/usr/bin/pkill -x "$EXECUTABLE_NAME" 2>/dev/null || true
/usr/bin/pkill -x "$OLD_EXECUTABLE_NAME" 2>/dev/null || true
/bin/mkdir -p "$INSTALL_DIR"
/bin/rm -rf "$INSTALL_APP"
/bin/rm -rf "$OLD_INSTALL_APP"
/bin/rm -rf "$SPACED_INSTALL_APP"
/usr/bin/ditto "$SOURCE_APP" "$INSTALL_APP"
/usr/bin/xattr -dr com.apple.quarantine "$INSTALL_APP" 2>/dev/null || true
/usr/bin/open -a "$INSTALL_APP"

echo "已安装到 $INSTALL_APP"
