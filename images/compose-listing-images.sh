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
VERTICAL_OFFSET=750 # empirical, based on spacing of the text in the background image
CORNER_RADIUS=140 # empirical
SHADOW_OFFSET=0
SHADOW_BLUR=15

OUTPUT_DIRECTORY="composed"

BACKGROUNDS=(
    "backgrounds/01.png"
    "backgrounds/02.png"
    "backgrounds/03.png"
    "backgrounds/04.png"
)

OVERLAYS=(
    "screenshots/02-basic-results.png"
    "screenshots/03-result-format.png"
    "screenshots/06-rounding-error.png"
    "screenshots/08-square-inch-result.png"
)

if [ "${#BACKGROUNDS[@]}" -ne "${#OVERLAYS[@]}" ]; then
    echo "Error: background and overlay lists must be the same length."
    exit 1
fi

SCALED_OVERLAY_WIDTH=$(echo "$BG_WIDTH - 2 * $HORIZONTAL_MARGIN" | bc)
SCALED_OVERLAY_HEIGHT=$(echo "scale=0; $SCALED_OVERLAY_WIDTH * $OVERLAY_HEIGHT / $OVERLAY_WIDTH" | bc)
SHADOW_PAD=$((SHADOW_BLUR * 2))
COMPOSITE_X=$(( (BG_WIDTH - SCALED_OVERLAY_WIDTH) / 2 - SHADOW_PAD ))
COMPOSITE_Y=$(( VERTICAL_OFFSET - SHADOW_PAD ))

for i in {1..${#BACKGROUNDS[@]}}; do
    bg="${BACKGROUNDS[$i]}"
    overlay="${OVERLAYS[$i]}"

    bg_base="$(basename "${bg%.*}")"
    overlay_base="$(basename "${overlay%.*}")"
    output="${OUTPUT_DIRECTORY}/${i}_${bg_base}_${overlay_base}.png"

    echo "Composing $overlay onto $bg -> $output"

    # Scale overlay and clip corners to a rounded rectangle
    transformed_overlay="$(mktemp /tmp/overlay_XXXXXX.png)"
    magick "$overlay" \
        -resize "${SCALED_OVERLAY_WIDTH}x${SCALED_OVERLAY_HEIGHT}!" \
        -alpha set \
        \( +clone -alpha transparent \
           -fill white -draw "roundrectangle 0,0,${SCALED_OVERLAY_WIDTH},${SCALED_OVERLAY_HEIGHT},${CORNER_RADIUS},${CORNER_RADIUS}" \) \
        -compose DstIn -composite \
        "$transformed_overlay"

    # Add drop shadow and composite onto background
    magick "$bg" -resize "${BG_WIDTH}x${BG_HEIGHT}!" \
        \( "$transformed_overlay" \
           \( +clone -background none -shadow "80x${SHADOW_BLUR}+0+${SHADOW_OFFSET}" \) \
           +swap -background none -layers merge \) \
        -geometry "+${COMPOSITE_X}+${COMPOSITE_Y}" \
        -compose Over -composite \
        "$output"

    rm "$transformed_overlay"

done
