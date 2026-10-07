#!/usr/bin/env bash
# Switch Waybar colour theme:  theme.sh mocha | tokyonight | gruvbox
dir="$(cd "$(dirname "$0")/.." && pwd)/colors"
name="${1:-}"
if [[ -z "$name" || ! -f "$dir/$name.css" ]]; then
  echo "usage: theme.sh <name>"
  echo "available: $(cd "$dir" && ls *.css | grep -v '^colors.css$' | sed 's/\.css//' | tr '\n' ' ')"
  exit 1
fi
cp "$dir/$name.css" "$dir/colors.css"
pkill -SIGUSR2 waybar && echo "switched to $name"
