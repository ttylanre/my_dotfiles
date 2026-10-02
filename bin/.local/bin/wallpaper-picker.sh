#!/bin/bash
DIR="$HOME/Pictures/wallpapers"

# 1. Select wallpaper with preview
selected=$(
  find "$DIR" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) ! -name "blur_*" | fzf \
    --preview='chafa --size=$(( $FZF_PREVIEW_COLUMNS ))x$(( $FZF_PREVIEW_LINES )) -- {}' \
    --preview-window=right:60%
)

# Exit if no file was selected
[ -z "$selected" ] && exit 0

clear

# 2. Pick a random transition for main wallpaper
TRANSITIONS=(wipe wave grow fade outer)
TRANSITION=${TRANSITIONS[$RANDOM % ${#TRANSITIONS[@]}]}

# 3. Set the main wallpaper
awww img "$selected" --transition-type "$TRANSITION"

# 4. Remove any previous blurred wallpapers to keep your directory clean
find "$DIR" -maxdepth 1 -type f -name "blur_*" -delete

# 5. Generate new blurred image and set it to the 'overview-wall' target
filename=$(basename "$selected")
blurred_path="$DIR/blur_$filename"

magick "$selected" -blur 0x9 "$blurred_path"
awww img -n overview-wall "$blurred_path"
