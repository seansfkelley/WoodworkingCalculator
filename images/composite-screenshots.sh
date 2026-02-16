#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")"

# Required by App Store Connect
BG_WIDTH=1284
BG_HEIGHT=2778

# iPhone 17 Pro dimensions
OVERLAY_WIDTH=1206
OVERLAY_HEIGHT=2622

# to taste
HORIZONTAL_MARGIN=100
VERTICAL_OFFSET=650

BACKGROUNDS=(
    "backgrounds/01.png"
    "backgrounds/01.png"
    "backgrounds/01.png"
    "backgrounds/01.png"
)

OVERLAYS=(
    "screenshots/02-basic-results.png"
    "screenshots/03-result-format.png"
    "screenshots/06-rounding-error.png"
    "screenshots/08-square-inch-result.png"
)

OUTPUT_DIRECTORY="merged"

SCALED_OVERLAY_WIDTH=$(echo "$BG_WIDTH - 2 * $HORIZONTAL_MARGIN" | bc)
SCALED_OVERLAY_HEIGHT=$(echo "scale=0; $SCALED_OVERLAY_WIDTH * $OVERLAY_HEIGHT / $OVERLAY_WIDTH" | bc)

OFFSET_X="$HORIZONTAL_MARGIN"
OFFSET_Y="$VERTICAL_OFFSET"

if [ "${#BACKGROUNDS[@]}" -ne "${#OVERLAYS[@]}" ]; then
    echo "Error: background and overlay lists must be the same length."
    exit 1
fi

for i in {1..${#BACKGROUNDS[@]}}; do
    bg="${BACKGROUNDS[$i]}"
    overlay="${OVERLAYS[$i]}"

    bg_base="$(basename "${bg%.*}")"
    overlay_base="$(basename "${overlay%.*}")"
    output="${OUTPUT_DIRECTORY}/${i}_${bg_base}_${overlay_base}.png"

    echo "Merging $overlay onto $bg -> $output"

    magick "$bg" \
        \( "$overlay" -resize "${SCALED_OVERLAY_WIDTH}x${SCALED_OVERLAY_HEIGHT}!" \) \
        -gravity NorthWest \
        -geometry "+${OFFSET_X}+${OFFSET_Y}" \
        -composite \
        "$output"
done

echo "Done."
