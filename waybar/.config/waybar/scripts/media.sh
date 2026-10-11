#!/usr/bin/env bash
# Scrolling "now playing" for waybar (marquee). Requires: playerctl
# Long titles scroll; short ones stay still. Paused = frozen + dimmed.
# Hides itself (empty text) when nothing is playing.

export LC_ALL=C.UTF-8 # character-based string slicing, even in a C locale

# ---- tweak these ----
WIDTH=24      # visible characters of text
STEP=0.25     # seconds per scroll step (smaller = faster)
HOLD=10       # steps to pause at the start of each loop
GAP="   ·   " # separator between repeats
# ---------------------

ICON_PLAY=$'\xf3\xb0\x8e\x86'
ICON_PAUSE=$'\xf3\xb0\x8f\xa4'
SEP=$'\x1f'
FORMAT="{{status}}${SEP}{{artist}}${SEP}{{title}}${SEP}{{album}}"

status="" artist="" title="" album="" text="" pos=0 hold=0 last="" ticks=0

esc() {
	local s=$1
	s=${s//\\/\\\\}
	s=${s//\"/\\\"}
	s=${s//$'\n'/ }
	s=${s//$'\t'/ }
	printf '%s' "$s"
}

emit() { # emit <text> <tooltip> <class>
	local out
	out=$(printf '{"text":"%s","tooltip":"%s","class":["%s"]}' "$(esc "$1")" "$2" "$3")
	if [[ $out != "$last" ]]; then
		printf '%s\n' "$out"
		last=$out
	fi
}

parse() {
	IFS=$SEP read -r status artist title album <<<"$1"
	local new
	if [[ -n $artist ]]; then new="$artist - $title"; else new="$title"; fi
	if [[ $new != "$text" ]]; then
		text=$new
		pos=0
		hold=0
	fi
}

tick() {
	[[ $status == Playing ]] || return
	((${#text} > WIDTH)) || return
	local loopl=$((${#text} + ${#GAP}))
	if ((pos == 0 && hold < HOLD)); then
		hold=$((hold + 1))
	else
		pos=$(((pos + 1) % loopl))
		hold=0
	fi
}

render() {
	if [[ -z $status || $status == Stopped || -z $text ]]; then
		emit "" "" none
		return
	fi
	local cls icon view loop doubled tip
	if [[ $status == Playing ]]; then
		cls=playing
		icon=$ICON_PLAY
	else
		cls=paused
		icon=$ICON_PAUSE
	fi

	if ((${#text} <= WIDTH)); then
		view=$text
	elif [[ $cls == paused ]]; then
		view="${text:0:WIDTH-1}…"
	else
		loop="$text$GAP"
		doubled="$loop$loop"
		view=${doubled:pos:WIDTH}
	fi

	tip=$(esc "$text")
	[[ -n $album ]] && tip+="\\n$(esc "$album")"
	emit "$icon $view" "$tip" "$cls"
}

poll() { # slow safety net: catches players that vanish or were missed
	local line
	if line=$(playerctl metadata --format "$FORMAT" 2>/dev/null) && [[ -n $line ]]; then
		parse "$line"
	else
		status="" text=""
	fi
}

start_follow() { exec {FD}< <(playerctl --follow metadata --format "$FORMAT" 2>/dev/null); }
trap 'exec {FD}<&- 2> /dev/null; pkill -P $$' EXIT

start_follow
poll
render

while true; do
	if read -r -t "$STEP" line <&"$FD"; then
		[[ -n $line ]] && parse "$line"
	else
		rc=$?
		if ((rc <= 128)); then # EOF: follower died, restart it
			exec {FD}<&-
			sleep 1
			start_follow
			status="" text=""
		else # timeout: advance the marquee
			tick
			ticks=$((ticks + 1))
			((ticks % 8 == 0)) && poll
		fi
	fi
	render
done
