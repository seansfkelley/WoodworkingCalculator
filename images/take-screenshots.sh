#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")"

# Configuration
SCHEME="WoodworkingCalculator"
SIMULATOR_NAME="iPhone 17 Pro"
SIMULATOR_OS="26.2"
DERIVED_DATA_DIR="$(mktemp -d)"
OUTPUT_DIR="screenshots"

BUNDLE_ID="woodworking.calculator"

DESTINATION="platform=iOS Simulator,name=${SIMULATOR_NAME},OS=${SIMULATOR_OS}"
DEVICE_UDID=$(xcrun simctl list devices --json \
    | jq -r --arg name "$SIMULATOR_NAME" --arg os "com.apple.CoreSimulator.SimRuntime.iOS-${SIMULATOR_OS//./-}" \
    '.devices[$os][] | select(.name == $name) | .udid' \
    | head -1)

echo "Booting simulator and uninstalling app to reset state..."
xcrun simctl boot "$DEVICE_UDID" 2>/dev/null || true
xcrun simctl uninstall "$DEVICE_UDID" "$BUNDLE_ID"

echo "Building and running screenshot tests..."

xcodebuild test \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -only-testing "Wood Calc UI Tests/AppStoreScreenshotTests" \
    -derivedDataPath "$DERIVED_DATA_DIR"

RESULT_BUNDLE=$(find "$DERIVED_DATA_DIR" -name "*.xcresult" | head -1)

if [[ -z "$RESULT_BUNDLE" ]]; then
    echo "Error: no .xcresult bundle found in $DERIVED_DATA_DIR"
    exit 1
fi

echo "Extracting screenshots from $RESULT_BUNDLE..."

EXPORT_STAGING="$(mktemp -d)"
xcrun xcresulttool export attachments \
    --path "$RESULT_BUNDLE" \
    --output-path "$EXPORT_STAGING"

mkdir -p "$OUTPUT_DIR"

attachments=$(jq -r '.[] | .attachments[] | [.exportedFileName, .suggestedHumanReadableName] | @tsv' \
    "$EXPORT_STAGING/manifest.json")

while IFS=$'\t' read -r exported_name human_name; do
    human_name=$(sed -E 's/_[0-9]+_[0-9A-Fa-f-]+\.png$/.png/' <<< "$human_name")
    dst="$OUTPUT_DIR/${human_name}"
    echo "Saving $human_name -> $dst"
    cp "$EXPORT_STAGING/$exported_name" "$dst"
done <<< "$attachments"

echo "Done. Screenshots saved to $OUTPUT_DIR/"
