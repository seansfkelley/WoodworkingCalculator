#!/bin/zsh

BG_WIDTH=1000
BG_HEIGHT=2000
OVERLAY_WIDTH=500
OVERLAY_HEIGHT=800
HORIZONTAL_MARGIN=40
VERTICAL_OFFSET=100

BACKGROUNDS=(
    "bg1.png"
    "bg2.png"
    "bg3.png"
)

OVERLAYS=(
    "overlay1.png"
    "overlay2.png"
    "overlay3.png"
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

for i in "${!BACKGROUNDS[@]}"; do
    bg="${BACKGROUNDS[$i]}"
    overlay="${OVERLAYS[$i]}"

    bg_base="${$(basename "$bg")%.*}"
    overlay_base="${$(basename "$overlay")%.*}"
    output="${OUTPUT_DIRECTORY}/$((i + 1))_${bg_base}_${overlay_base}.png"

    echo "Merging $overlay onto $bg -> $output"

    magick "$bg" \
        \( "$overlay" -resize "${SCALED_OVERLAY_WIDTH}x${SCALED_OVERLAY_HEIGHT}!" \) \
        -gravity NorthWest \
        -geometry "+${OFFSET_X}+${OFFSET_Y}" \
        -composite \
        "$output"
done

echo "Done."
