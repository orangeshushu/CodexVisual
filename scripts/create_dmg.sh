#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="CodexVisual"
EXECUTABLE_NAME="CodexVisual"
OLD_EXECUTABLE_NAME="CodexQuotaBar"
VOL_NAME="CodexVisual"
BUILD_DIR="$ROOT_DIR/build"
APP_PATH="$BUILD_DIR/$APP_NAME.app"
DMG_ROOT="$BUILD_DIR/dmg-root"
DMG_PATH="$BUILD_DIR/CodexVisual.dmg"

"$ROOT_DIR/scripts/build_app.sh" >/dev/null

/bin/rm -rf "$DMG_ROOT" "$DMG_PATH"
/bin/mkdir -p "$DMG_ROOT"

/usr/bin/ditto "$APP_PATH" "$DMG_ROOT/$APP_NAME.app"
/bin/ln -s /Applications "$DMG_ROOT/Applications"

/bin/cat > "$DMG_ROOT/卸载 CodexVisual.command" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

APP_NAME="CodexVisual"
EXECUTABLE_NAME="CodexVisual"
OLD_EXECUTABLE_NAME="CodexQuotaBar"

/usr/bin/pkill -x "$EXECUTABLE_NAME" 2>/dev/null || true
/usr/bin/pkill -x "$OLD_EXECUTABLE_NAME" 2>/dev/null || true
/bin/rm -rf "/Applications/$APP_NAME.app"
/bin/rm -rf "$HOME/Applications/$APP_NAME.app"
/bin/rm -rf "/Applications/CodexQuotaBar.app"
/bin/rm -rf "$HOME/Applications/CodexQuotaBar.app"
/bin/rm -rf "/Applications/Codex Visual.app"
/bin/rm -rf "$HOME/Applications/Codex Visual.app"
/bin/rm -rf "$HOME/Library/Application Support/CodexVisual"
/bin/rm -rf "$HOME/Library/Application Support/CodexQuotaBar"

/usr/bin/osascript -e 'display dialog "CodexVisual 已卸载。" buttons {"好"} default button "好" with title "CodexVisual"'
SCRIPT

/bin/chmod +x "$DMG_ROOT/卸载 CodexVisual.command"

/bin/cat > "$DMG_ROOT/使用说明.txt" <<'TEXT'
安装：
1. 把 CodexVisual.app 拖到 Applications。
2. 从 Applications 打开 CodexVisual.app。
3. 菜单栏会显示 Codex 额度；点击菜单可查看刷新时间。

卸载：
双击“卸载 CodexVisual.command”。

说明：
这是一个本地菜单栏 app，只读取 ~/.codex/logs_2.sqlite 中 Codex 自己记录的额度事件。
如果 Codex 暂时没有写入新的额度事件，菜单栏会显示 Codex -- / --%，点击菜单可查看原因。
菜单栏数字顺序是：5小时 / 7天，例如 Codex 67 / 95%。
TEXT

/usr/bin/hdiutil create \
  -volname "$VOL_NAME" \
  -srcfolder "$DMG_ROOT" \
  -ov \
  -fs HFS+ \
  -format UDZO \
  "$DMG_PATH" >/dev/null

/usr/bin/codesign --force --sign - "$DMG_PATH" >/dev/null 2>&1 || true

echo "$DMG_PATH"
