#!/usr/bin/env zsh

set -euo pipefail

cd "${0:A:h}"

echo "building..."

# adapted from https://stackoverflow.com/questions/2664885/xcode-build-and-archive-from-command-line
# Note the warnings there about Xcode maybe not respecting build configuration. This seems to work
# but I don't really understand the subtleties.
xcodebuild -scheme WoodworkingCalculator clean archive -configuration release -archivePath /tmp/WoodworkingCalculator.xcarchive -quiet

echo "packaging..."

rm -rf ./scratch || true
rm -rf WoodCalc.ipa
mkdir -p scratch/Payload
mv /tmp/WoodworkingCalculator.xcarchive/Products/Applications/Wood\ Calc.app scratch/Payload
cd scratch
zip -q -r WoodCalc.ipa Payload
mv WoodCalc.ipa ..

echo "done!"
echo "result at <project>/WoodCalc.ipa"
