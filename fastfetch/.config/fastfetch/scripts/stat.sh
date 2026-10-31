#!/bin/bash
# Usage: stat.sh <github|activity|langs|lastpush|anilist>
f="${XDG_CACHE_HOME:-$HOME/.cache}/fastfetch/$1"
if [ -s "$f" ]; then
	cat "$f"
else
	echo "updating…"
	# flock stops several rows from launching several updaters at once
	(setsid flock -n "${XDG_RUNTIME_DIR:-/tmp}/fastfetch-stats.lock" \
		~/.config/fastfetch/scripts/update-stats.sh >/dev/null 2>&1 &)
fi
