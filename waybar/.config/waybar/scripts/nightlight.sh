#!/usr/bin/env bash
# Night-light override for wlsunset (niri implements wlr-gamma-control).
#
#   nightlight.sh on       force the warm (low) temperature now
#   nightlight.sh off      hand control back to wlsunset's normal day/night schedule
#   nightlight.sh toggle   flip between the two
#   nightlight.sh status   print "true" while forced warm, else "false"
#
# How it works: wlsunset has no on/off switch. Sending it SIGUSR1 cycles
#   forced high (day) -> forced low (warm) -> automatic -> forced high ...
# so this script steers YOUR running wlsunset to the mode you want, keeping
# your own flags and location. The warm colour is whatever your wlsunset's -t is.
# wlsunset can't be asked which mode it is in, so the script remembers what it
# last set (per process id). A freshly started wlsunset is assumed to be automatic.
# Use this script, not a manual `pkill -USR1`, or the remembered mode will drift.
#
# Only used if wlsunset is NOT already running, so the button still works:
WLSUNSET_ARGS="${WLSUNSET_ARGS:--l 6.5 -L 3.4 -t 4000}" # edit coordinates/temperature

STATE="${XDG_RUNTIME_DIR:-/tmp}/waybar-nightlight.state" # "<pid> <mode>"

pid() { # a live (non-zombie) wlsunset
	local p
	for p in $(pgrep -x wlsunset 2>/dev/null); do
		[[ $(ps -o stat= -p "$p" 2>/dev/null) == Z* ]] && continue
		echo "$p"
		return 0
	done
	return 1
}

mode() { # mode <pid>  ->  auto | high | low
	local sp="" sm=""
	[[ -r $STATE ]] && read -r sp sm <"$STATE"
	if [[ $sp == "$1" && -n $sm ]]; then echo "$sm"; else echo auto; fi
}

next_of() { case $1 in high) echo low ;; low) echo auto ;; *) echo high ;; esac }

goto() { # goto <pid> <target mode>
	local p=$1 target=$2 cur n=0
	cur=$(mode "$p")
	while [[ $cur != "$target" && $n -lt 3 ]]; do
		kill -USR1 "$p" 2>/dev/null || return 1
		cur=$(next_of "$cur")
		n=$((n + 1))
		sleep 0.05
	done
	echo "$p $cur" >"$STATE"
}

ensure() { # make sure a wlsunset is running; sets $P
	P=$(pid) && return 0
	# shellcheck disable=SC2086
	setsid -f wlsunset $WLSUNSET_ARGS >/dev/null 2>&1
	sleep 0.7 # SIGUSR1 kills a process that hasn't installed its handler yet
	P=$(pid)
}

status() {
	local p
	p=$(pid) && [[ $(mode "$p") == low ]] && echo true || echo false
}

do_on() { ensure && goto "$P" low; }
do_off() {
	local p
	p=$(pid) && goto "$p" auto
}

case "${1:-toggle}" in
on) do_on ;;
off) do_off ;;
status) status ;;
toggle) if [[ $(status) == true ]]; then do_off; else do_on; fi ;;
*)
	echo "usage: $0 [toggle|on|off|status]" >&2
	exit 1
	;;
esac
