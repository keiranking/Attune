#!/usr/bin/env bash
set -euo pipefail

: "${SCHEME:?Missing SCHEME}"
: "${APP_NAME:?Missing APP_NAME}"
: "${APPLE_ID:?Missing APPLE_ID}"
: "${APPLE_TEAM_ID:?Missing APPLE_TEAM_ID}"
: "${APPLE_APP_SPECIFIC_PASSWORD:?Missing APPLE_APP_SPECIFIC_PASSWORD}"

echo "Cleaning..."
rm -rf build
mkdir -p build

echo "Building archive..."
xcodebuild archive \
  -scheme "$SCHEME" \
  -configuration Release \
  -archivePath build/$SCHEME.xcarchive

echo "Exporting signed app..."
xcodebuild -exportArchive \
  -archivePath build/$SCHEME.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist

echo "Verifying codesign..."
codesign --verify --deep --strict build/export/$APP_NAME.app

echo "Attempting to staple..."
if xcrun stapler staple "build/export/$APP_NAME.app"; then
  echo "Already notarized."
else
  echo "Not notarized yet."

  echo "Creating temporary zip..."
  (cd build/export && zip -r "$APP_NAME.notarize.zip" "$APP_NAME.app")

  echo "Submitting for notarization (with 15-min timeout)..."
  timeout 900 xcrun notarytool submit \
    "build/export/$APP_NAME.notarize.zip" \
    --apple-id "$APPLE_ID" \
    --team-id "$APPLE_TEAM_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD" \
    --wait || {
      echo "Notarization still pending after 15 min. Re-run later."
      exit 1
    }

  echo "Stapling after notarization..."
  xcrun stapler staple "build/export/$APP_NAME.app"
fi

xcrun stapler validate "build/export/$APP_NAME.app"

echo "Creating distributable zip (with stapled app)"
(cd build/export && zip -r "$APP_NAME.zip" "$APP_NAME.app")

echo "Performing Gatekeeper check..."
spctl --assess --type execute "build/export/$APP_NAME.app"

echo "✅ Release created (build/export/$APP_NAME.zip)."
