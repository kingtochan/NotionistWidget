#!/usr/bin/env bash
# build-release.sh — builds NotionistWidgetApp and zips it for distribution
# Usage: ./build-release.sh [version]
# Example: ./build-release.sh 1.0.0

set -e

VERSION=${1:-"release"}
ZIP_NAME="NotionistWidget-v${VERSION}.zip"
DERIVED_DATA="build/DerivedData"
PRODUCTS="$DERIVED_DATA/Build/Products/Release"
INTERMEDIATES="$DERIVED_DATA/Build/Intermediates.noindex/NotionistWidget.build/Release"

echo "→ Cleaning previous build..."
rm -rf "$DERIVED_DATA"

echo "→ Stripping extended attributes from source..."
find . -not -path './.git/*' -exec xattr -c {} + 2>/dev/null || true

echo "→ Building (signing deferred)..."
xcodebuild \
  -project NotionistWidget.xcodeproj \
  -scheme NotionistWidgetApp \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  build

echo "→ Stripping extended attributes from build products..."
xattr -cr "$PRODUCTS"

APPEX="$PRODUCTS/NotionistWidgetExtension.appex"
APP="$PRODUCTS/NotionistWidgetApp.app"
EMBEDDED_APPEX="$APP/Contents/PlugIns/NotionistWidgetExtension.appex"
APPEX_XCENT="$INTERMEDIATES/NotionistWidgetExtension.build/NotionistWidgetExtension.appex.xcent"
APP_XCENT="$INTERMEDIATES/NotionistWidgetApp.build/NotionistWidgetApp.app.xcent"

echo "→ Signing widget extension (embedded)..."
if [ -f "$APPEX_XCENT" ]; then
  /usr/bin/codesign --force --sign - \
    --entitlements "$APPEX_XCENT" \
    --timestamp=none --generate-entitlement-der \
    "$EMBEDDED_APPEX"
else
  /usr/bin/codesign --force --sign - --timestamp=none "$EMBEDDED_APPEX"
fi

echo "→ Signing app..."
if [ -f "$APP_XCENT" ]; then
  /usr/bin/codesign --force --sign - \
    --entitlements "$APP_XCENT" \
    --timestamp=none --generate-entitlement-der \
    "$APP"
else
  /usr/bin/codesign --force --sign - --timestamp=none "$APP"
fi

echo "→ Zipping..."
cd "$PRODUCTS"
zip -r "$OLDPWD/$ZIP_NAME" NotionistWidgetApp.app
cd "$OLDPWD"

echo ""
echo "✓ Done! Upload this file to your GitHub Release:"
echo "  $ZIP_NAME"
