#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="CodexVisual"
VOL_NAME="CodexVisual"
BUILD_DIR="$ROOT_DIR/build"
PKG_PATH="$BUILD_DIR/$APP_NAME.pkg"
DMG_ROOT="$BUILD_DIR/dmg-root"
DMG_PATH="$BUILD_DIR/CodexVisual.dmg"
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:-}"
CODE_SIGN_KEYCHAIN="${CODE_SIGN_KEYCHAIN:-}"
CODE_SIGN_TIMESTAMP="${CODE_SIGN_TIMESTAMP:---timestamp}"

"$ROOT_DIR/scripts/create_pkg.sh" >/dev/null

/bin/rm -rf "$DMG_ROOT" "$DMG_PATH"
/bin/mkdir -p "$DMG_ROOT"

/bin/cp "$PKG_PATH" "$DMG_ROOT/$APP_NAME.pkg"
/usr/bin/ditto "$BUILD_DIR/$APP_NAME.app" "$DMG_ROOT/$APP_NAME.app"
/bin/cp "$ROOT_DIR/scripts/uninstall.sh" "$DMG_ROOT/Uninstall CodexVisual.command"
/bin/chmod +x "$DMG_ROOT/Uninstall CodexVisual.command"

/bin/cat > "$DMG_ROOT/Usage Guide.txt" <<'TEXT'
Install:
1. Double-click CodexVisual.pkg.
2. Follow the macOS Installer prompts.
3. The installer puts CodexVisual in /Applications and opens the app.
4. The menu bar shows your Codex quota and opens a control window.

Uninstall:
Option 1: Open the CodexVisual control window, then click "Uninstall CodexVisual".
Option 2: Double-click "Uninstall CodexVisual.command".

Notes:
CodexVisual is a local menu bar app. It asks the local Codex app service for the currently signed-in account quota.
If that service is unavailable, it falls back to recent local Codex sessions and logs.
If Codex --% keeps showing, open Codex, confirm you are signed in, then choose "Refresh Now" in the control window.
Future updates can be installed from "Check for Updates" in CodexVisual. You do not need to download manually again.
The menu bar shows the weekly remaining quota and reset countdown.

安装：
1. 双击 CodexVisual.pkg。
2. 按照 macOS Installer 的提示完成安装。
3. 安装器会把 CodexVisual 安装到 /Applications 并打开应用。
4. 菜单栏会显示 Codex 额度，同时会打开一个控制窗口。

卸载：
方法 1：打开 CodexVisual 控制窗口，点击“卸载 CodexVisual”。
方法 2：双击 “Uninstall CodexVisual.command”。

说明：
这是一个本地菜单栏 app，会通过本机 Codex 服务读取当前登录账号的额度。
如果本机服务暂时不可用，软件会回退读取最近的 Codex 会话和日志。
如果一直显示 Codex --%，请打开 Codex、确认已经登录，然后在控制窗口里选择“立即刷新”。
后续更新可以在控制窗口或 CodexVisual 菜单里选择“检查更新”，无需手动重新下载安装。
菜单栏只显示每周剩余额度百分比和重置倒计时。
TEXT

/usr/bin/hdiutil create \
  -volname "$VOL_NAME" \
  -srcfolder "$DMG_ROOT" \
  -ov \
  -fs HFS+ \
  -format UDZO \
  "$DMG_PATH" >/dev/null

if [[ -n "$CODE_SIGN_IDENTITY" && "$CODE_SIGN_IDENTITY" != "-" ]]; then
  timestamp_args=()
  if [[ "$CODE_SIGN_TIMESTAMP" == "none" ]]; then
    timestamp_args=(--timestamp=none)
  elif [[ -n "$CODE_SIGN_TIMESTAMP" && "$CODE_SIGN_TIMESTAMP" != "-" ]]; then
    timestamp_args=("$CODE_SIGN_TIMESTAMP")
  fi

  keychain_args=()
  if [[ -n "$CODE_SIGN_KEYCHAIN" ]]; then
    keychain_args=(--keychain "$CODE_SIGN_KEYCHAIN")
  fi

  /usr/bin/codesign \
    --force \
    --sign "$CODE_SIGN_IDENTITY" \
    "${keychain_args[@]}" \
    "${timestamp_args[@]}" \
    "$DMG_PATH" >/dev/null

  /usr/bin/codesign --verify --verbose=2 "$DMG_PATH" >/dev/null
else
  echo "Created unsigned DMG. Set CODE_SIGN_IDENTITY to create a public release build." >&2
fi

echo "$DMG_PATH"
