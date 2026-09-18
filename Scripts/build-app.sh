#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="MacLid"
BUNDLE_ID="com.francesco.maclid"
BUILD_DIR=".build/release"
APP_DIR=".build/${APP_NAME}.app"

swift build -c release --product "$APP_NAME"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$BUILD_DIR/$APP_NAME" "$APP_DIR/Contents/MacOS/$APP_NAME"

if [ ! -f Resources/AppIcon.icns ]; then
    swift run IconGenerator
    iconutil -c icns Resources/AppIcon.iconset -o Resources/AppIcon.icns
fi
cp Resources/AppIcon.icns "$APP_DIR/Contents/Resources/AppIcon.icns"

cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSHumanReadableCopyright</key>
    <string>frasntoro</string>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$APP_DIR" >/dev/null 2>&1 || true

echo "Bundle created at $APP_DIR"

if [ "${1:-}" = "--install" ]; then
    INSTALLED="/Applications/${APP_NAME}.app"

    # Quit the running copy first, so it isn't replaced underneath itself.
    osascript -e "quit app \"${APP_NAME}\"" >/dev/null 2>&1 || true
    sleep 1

    rm -rf "$INSTALLED"
    cp -R "$APP_DIR" /Applications/
    open "$INSTALLED"
    echo "Installed to $INSTALLED and relaunched"
else
    echo "Open it with: open $APP_DIR"
    echo "Install it with: $0 --install"
fi
