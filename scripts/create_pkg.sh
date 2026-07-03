#!/usr/bin/env bash
set -euo pipefail
export COPYFILE_DISABLE=1

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="CodexVisual"
APP_IDENTIFIER="com.orangeshushu.CodexVisual"
BUILD_DIR="$ROOT_DIR/build"
APP_PATH="$BUILD_DIR/$APP_NAME.app"
PKG_ROOT="$BUILD_DIR/pkg-root"
PKG_SCRIPTS="$BUILD_DIR/pkg-scripts"
COMPONENT_PKG="$BUILD_DIR/$APP_NAME-component.pkg"
COMPONENT_PLIST="$BUILD_DIR/$APP_NAME-component.plist"
PKG_PATH="$BUILD_DIR/$APP_NAME.pkg"
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:--}"
CODE_SIGN_KEYCHAIN="${CODE_SIGN_KEYCHAIN:-}"
PKG_SIGN_IDENTITY="${PKG_SIGN_IDENTITY:-${INSTALLER_SIGN_IDENTITY:-}}"
PKG_SIGN_KEYCHAIN="${PKG_SIGN_KEYCHAIN:-${CODE_SIGN_KEYCHAIN:-}}"

"$ROOT_DIR/scripts/build_app.sh" >/dev/null

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")"

/bin/rm -rf "$PKG_ROOT" "$PKG_SCRIPTS" "$COMPONENT_PKG" "$COMPONENT_PLIST" "$PKG_PATH"
/bin/mkdir -p "$PKG_ROOT" "$PKG_SCRIPTS"
STAGED_APP="$PKG_ROOT/$APP_NAME.app"
COPYFILE_DISABLE=1 /usr/bin/ditto --norsrc --noextattr "$APP_PATH" "$STAGED_APP"

/bin/cat > "$PKG_SCRIPTS/preinstall" <<'SCRIPT'
#!/bin/zsh
set -euo pipefail

/usr/bin/pkill -x "CodexVisual" 2>/dev/null || true
/usr/bin/pkill -x "CodexQuotaBar" 2>/dev/null || true
/bin/rm -rf "/Applications/CodexQuotaBar.app"
/bin/rm -rf "/Applications/Codex Visual.app"
/bin/rm -rf "$HOME/Applications/CodexVisual.app" 2>/dev/null || true
/bin/rm -rf "$HOME/Applications/CodexQuotaBar.app" 2>/dev/null || true
/bin/rm -rf "$HOME/Applications/Codex Visual.app" 2>/dev/null || true

CONSOLE_USER="$(/usr/bin/stat -f %Su /dev/console)"
if [[ -n "$CONSOLE_USER" && "$CONSOLE_USER" != "root" ]]; then
  USER_HOME="$(/usr/bin/dscl . -read "/Users/$CONSOLE_USER" NFSHomeDirectory 2>/dev/null | /usr/bin/awk '{print $2}')"
  if [[ -n "$USER_HOME" ]]; then
    /bin/rm -rf "$USER_HOME/Applications/CodexVisual.app" 2>/dev/null || true
    /bin/rm -rf "$USER_HOME/Applications/CodexQuotaBar.app" 2>/dev/null || true
    /bin/rm -rf "$USER_HOME/Applications/Codex Visual.app" 2>/dev/null || true
  fi
fi

exit 0
SCRIPT

/bin/cat > "$PKG_SCRIPTS/postinstall" <<'SCRIPT'
#!/bin/zsh
set -euo pipefail

/usr/bin/xattr -dr com.apple.quarantine "/Applications/CodexVisual.app" 2>/dev/null || true
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
  -f "/Applications/CodexVisual.app" 2>/dev/null || true

CONSOLE_USER="$(/usr/bin/stat -f %Su /dev/console)"
if [[ -n "$CONSOLE_USER" && "$CONSOLE_USER" != "root" ]]; then
  USER_ID="$(/usr/bin/id -u "$CONSOLE_USER" 2>/dev/null || true)"
  if [[ -n "$USER_ID" ]]; then
    /bin/launchctl asuser "$USER_ID" /usr/bin/open "/Applications/CodexVisual.app" 2>/dev/null || true
  fi
fi

exit 0
SCRIPT

/bin/chmod +x "$PKG_SCRIPTS/preinstall" "$PKG_SCRIPTS/postinstall"
/usr/bin/xattr -cr "$STAGED_APP" "$PKG_SCRIPTS" 2>/dev/null || true
/usr/bin/xattr -dr com.apple.provenance "$STAGED_APP" "$PKG_SCRIPTS" 2>/dev/null || true
/usr/bin/find "$STAGED_APP" "$PKG_SCRIPTS" -name '._*' -delete

/bin/cat > "$COMPONENT_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<array>
  <dict>
    <key>BundleHasStrictIdentifier</key>
    <true/>
    <key>BundleIsRelocatable</key>
    <false/>
    <key>BundleIsVersionChecked</key>
    <false/>
    <key>BundleOverwriteAction</key>
    <string>upgrade</string>
    <key>RootRelativeBundlePath</key>
    <string>$APP_NAME.app</string>
  </dict>
</array>
</plist>
PLIST

COPYFILE_DISABLE=1 /usr/bin/pkgbuild \
  --root "$PKG_ROOT" \
  --component-plist "$COMPONENT_PLIST" \
  --identifier "$APP_IDENTIFIER" \
  --version "$VERSION" \
  --install-location "/Applications" \
  --scripts "$PKG_SCRIPTS" \
  "$COMPONENT_PKG" >/dev/null

productbuild_args=(
  --package "$COMPONENT_PKG"
  --identifier "$APP_IDENTIFIER.installer"
  --version "$VERSION"
)

if [[ -n "$PKG_SIGN_IDENTITY" && "$PKG_SIGN_IDENTITY" != "-" ]]; then
  productbuild_args+=(--sign "$PKG_SIGN_IDENTITY")
  if [[ -n "$PKG_SIGN_KEYCHAIN" ]]; then
    productbuild_args+=(--keychain "$PKG_SIGN_KEYCHAIN")
  fi
fi

/usr/bin/productbuild "${productbuild_args[@]}" "$PKG_PATH" >/dev/null

if [[ -n "$PKG_SIGN_IDENTITY" && "$PKG_SIGN_IDENTITY" != "-" ]]; then
  /usr/sbin/pkgutil --check-signature "$PKG_PATH" >/dev/null
else
  echo "Created unsigned PKG. Set PKG_SIGN_IDENTITY='Developer ID Installer: ...' for public release builds." >&2
fi

echo "$PKG_PATH"
