#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="Logger Utility"
BUNDLE_NAME="$APP_NAME.app"
VERSION="1.0.0"
SIGNING_IDENTITY="Developer ID Application: Aaron Voges (HE8J54Z2AE)"

echo "==> Building release binary..."
cd "$PROJECT_DIR"
swift build -c release

echo "==> Creating .app bundle..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/$BUNDLE_NAME/Contents/MacOS"
mkdir -p "$BUILD_DIR/$BUNDLE_NAME/Contents/Resources"

cp "$PROJECT_DIR/.build/release/LoggerUtility" "$BUILD_DIR/$BUNDLE_NAME/Contents/MacOS/LoggerUtility"
cp "$PROJECT_DIR/Resources/AppIcon.icns" "$BUILD_DIR/$BUNDLE_NAME/Contents/Resources/AppIcon.icns"

cat > "$BUILD_DIR/$BUNDLE_NAME/Contents/Info.plist" << 'PLIST'
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
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
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
rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING"
cp -R "$BUILD_DIR/$BUNDLE_NAME" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

DMG_PATH="$BUILD_DIR/LoggerUtility-${VERSION}.dmg"
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_STAGING" \
    -ov -format UDZO \
    "$DMG_PATH"

codesign --sign "$SIGNING_IDENTITY" "$DMG_PATH"

rm -rf "$DMG_STAGING"

echo ""
echo "==> Build complete!"
echo "    App:  $BUILD_DIR/$BUNDLE_NAME"
echo "    DMG:  $DMG_PATH"
echo "    Size: $(du -h "$DMG_PATH" | cut -f1)"
