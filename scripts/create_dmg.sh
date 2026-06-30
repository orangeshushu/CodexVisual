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
CODE_SIGN_TIMESTAMP="${CODE_SIGN_TIMESTAMP:---timestamp}"

"$ROOT_DIR/scripts/create_pkg.sh" >/dev/null

/bin/rm -rf "$DMG_ROOT" "$DMG_PATH"
/bin/mkdir -p "$DMG_ROOT"

/bin/cp "$PKG_PATH" "$DMG_ROOT/$APP_NAME.pkg"
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
CodexVisual is a local menu bar app. It only reads local quota events written by Codex.
It checks ~/.codex/sessions, ~/.codex/logs_2.sqlite, and ~/.codex/sqlite/logs_2.sqlite.
If Codex has not written a current quota event yet, the menu bar shows Codex -- / --% and the control window explains why.
If Codex -- / --% keeps showing, open Codex, send one message, then choose "Refresh Now" in the control window.
Future updates can be installed from "Check for Updates" in CodexVisual. You do not need to download manually again.
The menu bar shows two quota windows by default: 5 hours / 7 days, remaining percentages, and reset countdowns.

安装：
1. 双击 CodexVisual.pkg。
2. 按照 macOS Installer 的提示完成安装。
3. 安装器会把 CodexVisual 安装到 /Applications 并打开应用。
4. 菜单栏会显示 Codex 额度，同时会打开一个控制窗口。

卸载：
方法 1：打开 CodexVisual 控制窗口，点击“卸载 CodexVisual”。
方法 2：双击 “Uninstall CodexVisual.command”。

说明：
这是一个本地菜单栏 app，只读取 Codex 自己记录的本地额度事件。
会检查 ~/.codex/logs_2.sqlite 和 ~/.codex/sqlite/logs_2.sqlite。
如果 Codex 暂时没有写入新的额度事件，菜单栏会显示 Codex -- / --%，控制窗口会显示原因。
如果一直显示 Codex -- / --%，请先打开 Codex 并发送一条消息，然后在控制窗口里选择“立即刷新”。
后续更新可以在控制窗口或 CodexVisual 菜单里选择“检查更新”，无需手动重新下载安装。
菜单栏默认显示两条进度：5小时 / 7天，并显示剩余额度百分比和重置倒计时。
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

  /usr/bin/codesign \
    --force \
    --sign "$CODE_SIGN_IDENTITY" \
    "${timestamp_args[@]}" \
    "$DMG_PATH" >/dev/null

  /usr/bin/codesign --verify --verbose=2 "$DMG_PATH" >/dev/null
else
  echo "Created unsigned DMG. Set CODE_SIGN_IDENTITY to create a public release build." >&2
fi

echo "$DMG_PATH"
