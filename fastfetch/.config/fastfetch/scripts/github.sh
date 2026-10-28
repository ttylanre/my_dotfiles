#!/bin/bash
f="${XDG_CACHE_HOME:-$HOME/.cache}/fastfetch/github"
if [ -s "$f" ]; then
	cat "$f"
else
	echo "updating…"
	(setsid ~/.config/fastfetch/scripts/update-stats.sh >/dev/null 2>&1 &)
fi
