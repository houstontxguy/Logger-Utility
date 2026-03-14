#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="Logger Utility"
BUNDLE_NAME="$APP_NAME.app"
VERSION="${1:-1.0.0}"
BUILD_NUMBER="${2:-1}"
SIGNING_IDENTITY="Developer ID Application: Aaron Voges (HE8J54Z2AE)"

echo "==> Building release binary..."
cd "$PROJECT_DIR"
swift build -c release

echo "==> Creating .app bundle..."
rm -rf "$BUILD_DIR/$BUNDLE_NAME"
mkdir -p "$BUILD_DIR/$BUNDLE_NAME/Contents/MacOS"
mkdir -p "$BUILD_DIR/$BUNDLE_NAME/Contents/Resources"

cp "$PROJECT_DIR/.build/release/LoggerUtility" "$BUILD_DIR/$BUNDLE_NAME/Contents/MacOS/LoggerUtility"
cp "$PROJECT_DIR/Resources/AppIcon.icns" "$BUILD_DIR/$BUNDLE_NAME/Contents/Resources/AppIcon.icns"

cat > "$BUILD_DIR/$BUNDLE_NAME/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>LoggerUtility</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.avoges.LoggerUtility</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Logger Utility</string>
    <key>CFBundleDisplayName</key>
    <string>Logger Utility</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${BUILD_NUMBER}</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright 2026 Aaron Voges. All rights reserved.</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.developer-tools</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

echo "==> Signing with Developer ID..."
codesign --deep --force --options runtime \
    --sign "$SIGNING_IDENTITY" \
    "$BUILD_DIR/$BUNDLE_NAME"

codesign --verify --deep --strict "$BUILD_DIR/$BUNDLE_NAME"
echo "    Signature verified."

echo "==> Creating DMG..."
DMG_STAGING="$BUILD_DIR/dmg-staging"
DMG_RW="$BUILD_DIR/LoggerUtility-rw.dmg"
DMG_PATH="$BUILD_DIR/LoggerUtility-${VERSION}.dmg"
VOLUME_NAME="$APP_NAME"

rm -rf "$DMG_STAGING" "$DMG_RW" "$DMG_PATH"
mkdir -p "$DMG_STAGING"
cp -R "$BUILD_DIR/$BUNDLE_NAME" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

# Create a read-write DMG so we can set Finder view options
hdiutil create -volname "$VOLUME_NAME" \
    -srcfolder "$DMG_STAGING" \
    -ov -format UDRW \
    "$DMG_RW"

# Mount the read-write DMG
MOUNT_DIR=$(hdiutil attach "$DMG_RW" -readwrite -noverify | grep "/Volumes/" | awk '{print substr($0, index($0, "/Volumes/"))}')
echo "    Mounted at: $MOUNT_DIR"

# Use AppleScript to configure Finder view
osascript << APPLESCRIPT
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {100, 100, 640, 400}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 80
        set position of item "$BUNDLE_NAME" of container window to {360, 150}
        set position of item "Applications" of container window to {160, 150}
        close
        open
        update without registering applications
        delay 1
        close
    end tell
end tell
APPLESCRIPT

# Ensure .DS_Store is flushed
sync

# Detach the DMG
hdiutil detach "$MOUNT_DIR" -quiet

# Convert to compressed read-only DMG
hdiutil convert "$DMG_RW" -format UDZO -o "$DMG_PATH"

# Sign the DMG
codesign --sign "$SIGNING_IDENTITY" "$DMG_PATH"

# Clean up
rm -rf "$DMG_STAGING" "$DMG_RW"

echo ""
echo "==> Build complete!"
echo "    App:  $BUILD_DIR/$BUNDLE_NAME"
echo "    DMG:  $DMG_PATH"
echo "    Size: $(du -h "$DMG_PATH" | cut -f1)"
