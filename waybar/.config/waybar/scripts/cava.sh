#!/usr/bin/env bash
# Waybar audio visualiser: runs cava in raw mode and maps 0-7 to block glyphs.
# Requires: cava  (sudo pacman -S cava)
# Waits for PipeWire at boot, restarts cava if it dies, and filters output so
# stray text can never reach the bar.

BARS=16
glyphs="▁▂▃▄▅▆▇█"

dict="s/;//g;"
for ((i = 0; i < ${#glyphs}; i++)); do
	dict+="s/$i/${glyphs:$i:1}/g;"
done

flat=""
for ((i = 0; i < BARS; i++)); do flat+="▁"; done

cfg=$(mktemp)
cat >"$cfg" <<CFG
[general]
framerate = 60
bars = $BARS

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

trap 'rm -f "$cfg"; pkill -P $$' EXIT

while true; do
	# wait until the audio server is actually up (boot race)
	until pactl info >/dev/null 2>&1; do
		echo "$flat"
		sleep 1
	done

	cava -p "$cfg" 2>/dev/null |
		grep --line-buffered -E '^[0-9;]+$' |
		sed -u "$dict"

	# cava exited: show idle bars, wait, retry
	echo "$flat"
	sleep 1
done
