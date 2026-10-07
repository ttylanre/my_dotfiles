#!/usr/bin/env bash
# Lock the screen with swaylock, themed to match the bar (Catppuccin Mocha).
# Requires: swaylock  (sudo pacman -S swaylock)
pgrep -x swaylock > /dev/null && exit 0
exec swaylock -f \
  --color 11111b \
  --inside-color 181825 --inside-clear-color 181825 \
  --inside-ver-color 181825 --inside-wrong-color 181825 \
  --ring-color 89b4fa --ring-clear-color f9e2af \
  --ring-ver-color a6e3a1 --ring-wrong-color f38ba8 \
  --key-hl-color cba6f7 --bs-hl-color f38ba8 \
  --line-color 00000000 --line-clear-color 00000000 \
  --line-ver-color 00000000 --line-wrong-color 00000000 \
  --separator-color 00000000 \
  --text-color cdd6f4 --text-clear-color cdd6f4 \
  --text-ver-color cdd6f4 --text-wrong-color cdd6f4 \
  --indicator-radius 80 --indicator-thickness 6
