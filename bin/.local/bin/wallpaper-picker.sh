#!/bin/bash
# Usage:
#   wallpaper-picker.sh           open the picker (ctrl-r inside = random)
#   wallpaper-picker.sh random    apply a random wallpaper, no UI (also: -r)

DIR="$HOME/Pictures/wallpapers"
SELF=$(readlink -f "$0")

# Prints "filename<TAB>fullpath" for every wallpaper (blurred copies excluded)
list_wallpapers() {
	find "$DIR" -maxdepth 1 -type f \
		\( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) \
		! -name "blur_*" -printf '%f\t%p\n' |
		awk -F'\t' -v OFS='\t' '{ sub(/\.[^.]+$/, "", $1); print }'
}

case "$1" in
# Internal helper used by fzf's ctrl-r binding
--random-line)
	list_wallpapers | shuf -n1
	exit 0
	;;

# Random mode: no UI
random | -r)
	selected=$(list_wallpapers | shuf -n1 | cut -f2)
	;;

# Picker mode
*)
	selected=$(
		list_wallpapers | sort -f | fzf \
			--delimiter=$'\t' \
			--with-nth=1 \
			--layout=reverse \
			--height=100% \
			--border=rounded \
			--border-label='  󰸉  Wallpapers  ' \
			--border-label-pos=3 \
			--padding=1,2 \
			--prompt='  ' \
			--pointer='▌' \
			--marker='✓' \
			--info=inline-right \
			--header='  enter apply  ·  ctrl-r random  ·  ctrl-d/u scroll preview  ·  ctrl-/ toggle preview  ·  esc quit' \
			--header-first \
			--no-scrollbar \
			--preview='chafa --animate=off --size=${FZF_PREVIEW_COLUMNS}x${FZF_PREVIEW_LINES} -- {2}' \
			--preview-window='right:60%:rounded' \
			--preview-label=' {1} ' \
			--bind="ctrl-r:become($SELF --random-line)" \
			--bind='ctrl-d:preview-half-page-down,ctrl-u:preview-half-page-up' \
			--bind='ctrl-/:toggle-preview' \
			--color='bg:-1,bg+:#313244,gutter:-1' \
			--color='fg:#cdd6f4,fg+:#ffffff,hl:#f38ba8,hl+:#f38ba8' \
			--color='info:#cba6f7,prompt:#cba6f7,pointer:#f5c2e7,marker:#a6e3a1,spinner:#f5e0dc' \
			--color='header:#89b4fa,border:#b4befe,label:#b4befe' \
			--color='preview-border:#585b70,preview-label:#f5c2e7'
	)
	selected=$(cut -f2 <<<"$selected")
	clear
	;;
esac

# Exit if nothing was selected
[ -z "$selected" ] && exit 0

# Pick a random transition
TRANSITIONS=(wipe wave grow fade outer)
TRANSITION=${TRANSITIONS[$RANDOM % ${#TRANSITIONS[@]}]}

# Set the main wallpaper
awww img "$selected" --transition-type "$TRANSITION"

# Clean old blurred wallpapers
find "$DIR" -maxdepth 1 -type f -name "blur_*" -delete

# Generate blurred copy and set it on the overview-wall target
filename=$(basename "$selected")
blurred_path="$DIR/blur_$filename"

# Runs fully detached (own session) so it survives the terminal closing
setsid -f bash -c '
  magick "$1" -blur 0x9 "$2" && awww img -n overview-wall "$2"
' _ "$selected" "$blurred_path" &>/dev/null
