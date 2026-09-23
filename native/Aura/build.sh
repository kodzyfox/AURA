#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "Aura requires macOS 14+ and Xcode Command Line Tools."
    exit 1
fi

if ! xcrun --find swift >/dev/null 2>&1; then
    echo "Install tools first: xcode-select --install"
    exit 1
fi

echo "==> Building Aura for macOS (release)..."
swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"

DIST_DIR="dist.noindex"
APP="$DIST_DIR/Aura.app"
rm -rf "$DIST_DIR" dist
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
ln -sfn "$DIST_DIR" dist

echo "==> Packaging Aura.app bundle..."
cp "$BIN_DIR/Aura" "$APP/Contents/MacOS/Aura"
cp Info.plist "$APP/Contents/Info.plist"

if [[ -d Resources ]]; then
    cp -R Resources/* "$APP/Contents/Resources/"
fi

echo "==> Building AuraWidget extension for Notification Center..."
WIDGET_APPEX="$APP/Contents/PlugIns/AuraWidget.appex"
mkdir -p "$WIDGET_APPEX/Contents/MacOS" "$WIDGET_APPEX/Contents/Resources"
cp Sources/AuraWidget/Info.plist "$WIDGET_APPEX/Contents/Info.plist"

xcrun swiftc -O -parse-as-library \
    -target arm64-apple-macos14.0 \
    -framework WidgetKit -framework SwiftUI -framework AppKit \
    Sources/AuraWidget/AuraWidget.swift \
    -o "$WIDGET_APPEX/Contents/MacOS/AuraWidget"

codesign --force --sign - "$WIDGET_APPEX"

echo "==> Signing with ad-hoc signature and entitlements..."
codesign --force --deep --sign - --entitlements Aura.entitlements "$APP"

echo "==> Creating branded distribution DMG (dist/Aura.dmg)..."
STAGING="dist/dmg_staging"
RW_DMG="dist/Aura_rw.dmg"
FINAL_DMG="dist/Aura.dmg"

# Clean up previous artifacts
rm -rf "$STAGING" "$RW_DMG" "$FINAL_DMG"
mkdir -p "$STAGING/.background"

# Populate staging directory
cp -R "$APP" "$STAGING/Aura.app"
ln -s /Applications "$STAGING/Applications"

if [[ -f Resources/dmg_background.png ]]; then
    cp Resources/dmg_background.png "$STAGING/.background/dmg_background.png"
fi

if [[ -f Resources/AppIcon.icns ]]; then
    cp Resources/AppIcon.icns "$STAGING/.VolumeIcon.icns"
fi

# Set file attributes if SetFile is available
if command -v SetFile >/dev/null 2>&1; then
    SetFile -a C "$STAGING" 2>/dev/null || true
    SetFile -a V "$STAGING/.background" 2>/dev/null || true
    SetFile -a V "$STAGING/.VolumeIcon.icns" 2>/dev/null || true
fi

# Create temporary read-write image with HFS+ (eliminates .fseventsd)
hdiutil create -volname "Aura" -srcfolder "$STAGING" -fs HFS+ -ov -format UDRW "$RW_DMG" >/dev/null

# Mount read-write image
MOUNT_OUTPUT=$(hdiutil attach -readwrite -noverify -noautoopen "$RW_DMG")
MOUNT_DIR=$(echo "$MOUNT_OUTPUT" | grep "/Volumes/Aura" | awk '{print $3}')
MOUNT_DEV=$(echo "$MOUNT_OUTPUT" | grep "/Volumes/Aura" | awk '{print $1}')

# Apply Finder view settings & layout via AppleScript
osascript << 'APPLESCRIPT'
tell application "Finder"
    tell disk "Aura"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {300, 150, 960, 570}
        set theViewOptions to the icon view options of container window
        set icon size of theViewOptions to 110
        set text size of theViewOptions to 12
        set label position of theViewOptions to bottom
        set arrangement of theViewOptions to not arranged
        try
            set background picture of theViewOptions to file "dmg_background.png" of folder ".background"
        end try
        
        -- Move all hidden items far off-screen so they never display in the window even with Cmd+Shift+.
        repeat with anItem in (get items of container window)
            set itemName to name of anItem as text
            if itemName is not "Aura.app" and itemName is not "Applications" then
                try
                    set position of anItem to {2500, 2500}
                end try
            end if
        end repeat
        
        try
            set position of item "Aura.app" of container window to {160, 248}
            set position of item "Applications" of container window to {500, 248}
        end try
        update without registering applications
        delay 1
        close
    end tell
end tell
APPLESCRIPT

if command -v SetFile >/dev/null 2>&1; then
    SetFile -a C "$MOUNT_DIR" 2>/dev/null || true
fi

sync
hdiutil detach "$MOUNT_DEV" -force >/dev/null

# Convert to final compressed UDZO image
hdiutil convert "$RW_DMG" -format UDZO -imagekey zlib-level=9 -o "$FINAL_DMG" >/dev/null

# Clean temporary files
rm -rf "$STAGING" "$RW_DMG"

echo ""
echo "✨ Build succeeded!"
echo "  • App bundle: dist/Aura.app"
echo "  • Distribution image: dist/Aura.dmg"
echo ""
echo "To install: open dist/Aura.dmg and drag Aura into Applications."
