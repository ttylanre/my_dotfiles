#!/bin/bash
# Network status for slstatus: wired/wifi, VPN, and latency.

# Wired interface that is up (skip wireless and virtual interfaces)
eth=""
for dev in /sys/class/net/*; do
	name=${dev##*/}
	[ "$(cat "$dev/operstate" 2>/dev/null)" = "up" ] || continue
	[ -d "$dev/wireless" ] && continue
	[ -d "$dev/phy80211" ] && continue
	case "$(readlink -f "$dev")" in */virtual/*) continue ;; esac
	eth=$name
	break
done

wifi_info=$(iw dev wlan0 link 2>/dev/null)

ping_out=$(ping -c 1 -W 1 1.1.1.1 2>/dev/null)
online=$?
lat=$(echo "$ping_out" | grep "time=" | sed -E 's/.*time=([0-9.]+).*/\1/' | cut -d. -f1)

vpn=$(ip link show 2>/dev/null | grep -E "tun0|wg0")

if [ -n "$eth" ]; then
	if [ $online -eq 0 ]; then
		[ -n "$vpn" ] && echo "󰈀 🔒 ${lat}ms" || echo "󰈀 ${lat}ms"
	else
		echo "⚠ Wired (No Net)"
	fi
elif echo "$wifi_info" | grep -q "Connected"; then
	ssid=$(echo "$wifi_info" | grep "SSID" | cut -d" " -f2- | sed 's/^ *//')

	# iw prints non-ASCII SSID bytes as \xNN escapes; decode them
	ssid=$(printf '%b' "$ssid")

	# Drop the SSID if it is empty or only invisible characters (e.g. U+3164)
	visible=${ssid//[[:space:]]/}
	visible=${visible//ㅤ/}
	[ -z "$visible" ] && ssid=""

	label="󰖩"
	[ -n "$ssid" ] && label="󰖩 $ssid"

	if [ $online -eq 0 ]; then
		[ -n "$vpn" ] && echo "$label 🔒 ${lat}ms" || echo "$label ${lat}ms"
	else
		echo "⚠ $label (No Net)"
	fi
else
	echo "󰖪 Disconnected"
fi
