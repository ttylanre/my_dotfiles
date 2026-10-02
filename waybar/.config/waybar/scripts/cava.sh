#!/usr/bin/env bash
# Waybar audio visualiser: runs cava in raw mode and maps 0-7 to block glyphs.
# Requires: cava  (sudo pacman -S cava)

bars="▁▂▃▄▅▆▇█"
dict="s/;//g;"
for ((i = 0; i < ${#bars}; i++)); do
	dict+="s/$i/${bars:$i:1}/g;"
done

cfg=$(mktemp)
cat >"$cfg" <<CFG
[general]
framerate = 60
bars = 16

[input]
method = pipewire
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
bar_delimiter = 59

[smoothing]
noise_reduction = 77
CFG

trap 'rm -f "$cfg"; kill 0' EXIT
cava -p "$cfg" | sed -u "$dict"
