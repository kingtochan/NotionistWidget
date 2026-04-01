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

# Source entitlements files (always available, used as fallback)
APPEX_ENT_SRC="WidgetExtension/NotionistWidget.entitlements"
APP_ENT_SRC="NotionistWidgetApp/NotionistWidgetApp.entitlements"

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

APP="$PRODUCTS/NotionistWidgetApp.app"
EMBEDDED_APPEX="$APP/Contents/PlugIns/NotionistWidgetExtension.appex"

# Use Xcode-generated .xcent if present, otherwise fall back to source entitlements
APPEX_XCENT="$INTERMEDIATES/NotionistWidgetExtension.build/NotionistWidgetExtension.appex.xcent"
APP_XCENT="$INTERMEDIATES/NotionistWidgetApp.build/NotionistWidgetApp.app.xcent"

if [ -f "$APPEX_XCENT" ]; then
  APPEX_ENT="$APPEX_XCENT"
else
  APPEX_ENT="$APPEX_ENT_SRC"
fi

if [ -f "$APP_XCENT" ]; then
  APP_ENT="$APP_XCENT"
else
  APP_ENT="$APP_ENT_SRC"
fi

echo "→ Signing widget extension with: $APPEX_ENT"
/usr/bin/codesign --force --sign - \
  --entitlements "$APPEX_ENT" \
  --timestamp=none --generate-entitlement-der \
  "$EMBEDDED_APPEX"

echo "→ Verifying widget extension entitlements..."
codesign -dv --entitlements :- "$EMBEDDED_APPEX" 2>/dev/null | grep -A 20 "<?xml" || true

echo "→ Signing app with: $APP_ENT"
/usr/bin/codesign --force --sign - \
  --entitlements "$APP_ENT" \
  --timestamp=none --generate-entitlement-der \
  "$APP"

echo "→ Zipping..."
cd "$PRODUCTS"
zip -r "$OLDPWD/$ZIP_NAME" NotionistWidgetApp.app
cd "$OLDPWD"

echo ""
echo "✓ Done! Upload this file to your GitHub Release:"
echo "  $ZIP_NAME"
