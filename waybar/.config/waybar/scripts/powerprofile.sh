#!/usr/bin/env bash
# Power-profile pill for waybar. Works with either backend:
#   - power-profiles-daemon, or TLP's tlp-pd (both answer to `powerprofilesctl`)
#   - `tlpctl` (TLP 1.9+, needs tlp-pd running) as a fallback
# TLP users: sudo pacman -S tlp-pd && sudo systemctl enable --now tlp-pd.service
#            (it replaces power-profiles-daemon; pacman will offer to remove it)
# Usage:  powerprofile.sh            print JSON for waybar (default)
#         powerprofile.sh next       cycle saver -> balanced -> performance -> saver
#         powerprofile.sh balanced   jump back to balanced

ICON_PERF=$'\xf3\xb0\x93\x85'
ICON_BAL=$'\xf3\xb0\xbe\x85'
ICON_SAVE=$'\xf3\xb0\xbe\x86'
SIGNAL=9 # must match "signal" in the waybar module

backend() {
	if command -v powerprofilesctl >/dev/null 2>&1 && powerprofilesctl get >/dev/null 2>&1; then
		echo ppd
	elif command -v tlpctl >/dev/null 2>&1 && tlpctl get >/dev/null 2>&1; then
		echo tlp
	fi
}
B=$(backend)

pget() {
	case $B in
	ppd) powerprofilesctl get 2>/dev/null ;;
	tlp) tlpctl get 2>/dev/null ;;
	esac
}

pset() {
	case $B in
	ppd) powerprofilesctl set "$1" 2>/dev/null ;;
	tlp) tlpctl set "$1" 2>/dev/null || tlpctl "$1" 2>/dev/null ;;
	esac
}

available() { # profiles this machine supports, in cycle order
	local all want
	if [[ $B == ppd ]]; then
		all=$(powerprofilesctl list 2>/dev/null | sed -nE 's/^[* ] ([a-z-]+):.*/\1/p')
	else
		all=$'power-saver\nbalanced\nperformance'
	fi
	for want in power-saver balanced performance; do
		grep -qx "$want" <<<"$all" && echo "$want"
	done
}

notify() {
	command -v notify-send >/dev/null 2>&1 || return 0
	notify-send -u low -t 1500 -h string:x-canonical-private-synchronous:powerprofile \
		"Power profile" "$1" 2>/dev/null
}

set_profile() {
	pset "$1" && notify "$1"
	pkill -RTMIN+$SIGNAL -x waybar 2>/dev/null
}

case "${1:-status}" in
next)
	[[ -n $B ]] || {
		notify "No power-profile service running"
		exit 1
	}
	cur=$(pget)
	mapfile -t profs < <(available)
	((${#profs[@]})) || exit 1
	next=${profs[0]}
	for i in "${!profs[@]}"; do
		if [[ ${profs[$i]} == "$cur" ]]; then next=${profs[$(((i + 1) % ${#profs[@]}))]}; fi
	done
	set_profile "$next"
	;;
balanced)
	[[ -n $B ]] || exit 1
	set_profile balanced
	;;
*)
	cur=$(pget)
	if [[ -z $B || -z $cur ]]; then
		printf '{"text":"","tooltip":"no power-profile service running","class":["offline"]}\n'
		exit 0
	fi
	case $cur in
	performance)
		icon=$ICON_PERF
		label="Performance"
		;;
	balanced)
		icon=$ICON_BAL
		label="Balanced"
		;;
	power-saver)
		icon=$ICON_SAVE
		label="Power saver"
		;;
	*)
		icon=$ICON_BAL
		label=$cur
		;;
	esac
	printf '{"text":"%s","tooltip":"Power profile: %s\\nClick to cycle, right-click for balanced","class":["%s"]}\n' \
		"$icon" "$label" "$cur"
	;;
esac
