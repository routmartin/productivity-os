#!/usr/bin/env bash
# build-mac.sh — Build the macOS Focus Companion as a proper .app bundle.
#
# Why: SwiftPM produces a raw Mach-O executable. macOS only routes URL
# schemes (e.g. productivityos://) to apps that are .app bundles with a
# CFBundleURLTypes entry in their Info.plist. This script:
#   1. Builds the ProductivityOSMac executable via SwiftPM.
#   2. Wraps it in ProductivityOSMac.app with Info.plist + Resources/.
#   3. Ad-hoc code-signs the bundle (no Apple Developer account needed
#      for local development).
#
# Usage:
#   scripts/build-mac.sh           # Debug build
#   scripts/build-mac.sh release   # Release build
#   open apps/ios/.build/ProductivityOSMac.app
#
# After opening the app, macOS Launch Services picks up the URL scheme
# registration. Test pairing by clicking a productivityos:// link in
# the web app's Settings page.

set -euo pipefail

CONFIG="${1:-debug}"
case "$CONFIG" in
  debug|release) ;;
  *) echo "Usage: $0 [debug|release]" >&2; exit 2 ;;
esac

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IOS_DIR="$ROOT/apps/ios"
APP_NAME="ProductivityOSMac"
DISPLAY_NAME="Productivity OS"
BUNDLE_ID="com.productivityos.mac"
BUNDLE_DIR="$IOS_DIR/.build/$APP_NAME.app"

cd "$IOS_DIR"

echo ">> Building $APP_NAME ($CONFIG)..."
# NOTE: must NOT use `--target` here. `swift build --target` compiles the
# executable target's sources but skips the final LINK step, so the runnable
# product is never produced/updated and a stale binary gets copied instead.
# Building all products (plain `swift build`) runs the linker.
swift build --configuration "$CONFIG"

BIN_PATH="$(swift build --configuration "$CONFIG" --show-bin-path)/$APP_NAME"
if [ ! -x "$BIN_PATH" ]; then
  echo "Built binary not found at $BIN_PATH" >&2
  exit 1
fi

echo ">> Assembling $BUNDLE_DIR..."
rm -rf "$BUNDLE_DIR"
mkdir -p "$BUNDLE_DIR/Contents/MacOS"
mkdir -p "$BUNDLE_DIR/Contents/Resources"

cp "$BIN_PATH" "$BUNDLE_DIR/Contents/MacOS/$APP_NAME"

# Substitute the actual executable name into the Info.plist.
sed -e "s|\$(EXECUTABLE_NAME)|$APP_NAME|g" \
    -e "s|\$(PRODUCT_NAME)|$DISPLAY_NAME|g" \
    MacCompanion/Info.plist > "$BUNDLE_DIR/Contents/Info.plist"

echo ">> Ad-hoc code signing..."
codesign --force --deep --sign - "$BUNDLE_DIR" >/dev/null

echo ""
echo "Built: $BUNDLE_DIR"
echo "Open with: open \"$BUNDLE_DIR\""
echo "After opening once, the 'productivityos://' URL scheme is registered with Launch Services."
