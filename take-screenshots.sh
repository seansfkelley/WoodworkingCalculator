#!/bin/zsh

set -euo pipefail

# Configuration
SCHEME="WoodworkingCalculator"
DESTINATION="platform=iOS Simulator,name=iPhone 17 Pro"
DERIVED_DATA_DIR="$(mktemp -d)"
OUTPUT_DIR="screenshots"

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
    human_name="${human_name//_[0-9]+_[0-9A-Fa-f-]+.png/.png}"
    dst="$OUTPUT_DIR/${human_name}"
    echo "Saving $human_name -> $dst"
    cp "$EXPORT_STAGING/$exported_name" "$dst"
done <<< "$attachments"

echo "Done. Screenshots saved to $OUTPUT_DIR/"
