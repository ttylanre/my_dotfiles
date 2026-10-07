#!/usr/bin/env bash
# Waybar audio visualiser. Runs cava in raw mode, maps 0-7 to block glyphs and
# emits JSON with a "class" (idle/low/mid/high) based on average loudness, so
# the pill's colour can react in style.css.
# Requires: cava  (sudo pacman -S cava)
# Waits for PipeWire at boot, restarts cava if it dies, and filters output so
# stray text can never reach the bar.

BARS=16

flat=""
for ((i = 0; i < BARS; i++)); do flat+="▁"; done
emit_flat() { printf '{"text":"%s","class":"idle"}\n' "$flat"; }

cfg=$(mktemp)
cat > "$cfg" << CFG
[general]
framerate = 30
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
  until pactl info > /dev/null 2>&1; do
    emit_flat
    sleep 1
  done

  cava -p "$cfg" 2> /dev/null \
    | grep --line-buffered -E '^[0-9;]+$' \
    | awk '
      BEGIN { split("▁ ▂ ▃ ▄ ▅ ▆ ▇ █", g, " ") }
      {
        n = split($0, v, ";"); out = ""; sum = 0; cnt = 0
        for (i = 1; i <= n; i++) {
          if (v[i] == "") continue
          out = out g[v[i] + 1]; sum += v[i]; cnt++
        }
        avg = cnt ? sum / cnt : 0
        cls = (avg < 0.3) ? "idle" : (avg < 2) ? "low" : (avg < 3.5) ? "mid" : "high"
        printf "{\"text\":\"%s\",\"class\":\"%s\"}\n", out, cls
        fflush()
      }'

  # cava exited: show idle bars, wait, retry
  emit_flat
  sleep 1
done
