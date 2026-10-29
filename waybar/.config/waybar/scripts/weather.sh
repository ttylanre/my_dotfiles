#!/usr/bin/env bash
# Waybar weather module (Open-Meteo: free, no API key).
# Requires: curl, jq
# Output: JSON for waybar (return-type json) with an icon + temperature,
# a Pango-marked-up tooltip (coloured from colors/colors.css), and CSS classes
# (clear/cloud/rain/storm/fog/snow, day/night, rain-likely, stale, offline).
# Caches the last good result for offline use.

# ---- edit these ----
LABEL="Lagos"
LAT="6.5244"
LON="3.3792"
RAIN_ALERT=50 # show rain % on the bar when chance in next 4h >= this
# --------------------

# icons are written as raw UTF-8 bytes so they survive any locale or paste
ICON_SUN=$'\xf3\xb0\x96\x99'
ICON_NIGHT=$'\xf3\xb0\x96\x94'
ICON_PARTLY=$'\xf3\xb0\x96\x95'
ICON_NPARTLY=$'\xf3\xb0\xbc\xb1'
ICON_CLOUD=$'\xf3\xb0\x96\x90'
ICON_FOG=$'\xf3\xb0\x96\x91'
ICON_RAINY=$'\xf3\xb0\x96\x97'
ICON_POUR=$'\xf3\xb0\x96\x96'
ICON_SNOW=$'\xf3\xb0\x96\x98'
ICON_STORM=$'\xf3\xb0\x99\xbe'
ICON_HUM=$'\xf3\xb0\x96\x8e'
ICON_WIND=$'\xf3\xb0\x96\x9d'
ICON_SUNRISE=$'\xf3\xb0\x96\x9c'
ICON_SUNSET=$'\xf3\xb0\x96\x9b'

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/waybar-weather.json"
mkdir -p "$(dirname "$CACHE")"

# ---- theme colours, read from the shared palette (falls back to Mocha) ----
COLORS_FILE="$(dirname "$(readlink -f "$0")")/../colors/colors.css"
col() { # col <name> <fallback>
	local v
	v=$(sed -n "s/^@define-color[[:space:]]\{1,\}$1[[:space:]]\{1,\}\(#[0-9a-fA-F]\{6\}\);.*/\1/p" "$COLORS_FILE" 2>/dev/null | head -1)
	printf '%s' "${v:-$2}"
}
C_TEXT=$(col text '#cdd6f4')
C_SUB=$(col subtext '#a6adc8')
C_DIM=$(col overlay '#6c7086')
C_BLUE=$(col blue '#89b4fa')
C_MAUVE=$(col mauve '#cba6f7')
C_SKY=$(col sky '#89dceb')
C_TEAL=$(col teal '#94e2d5')
C_GREEN=$(col green '#a6e3a1')
C_YELLOW=$(col yellow '#f9e2af')
C_PEACH=$(col peach '#fab387')
C_RED=$(col red '#f38ba8')

URL="https://api.open-meteo.com/v1/forecast?latitude=${LAT}&longitude=${LON}"
URL+="&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m,is_day"
URL+="&hourly=temperature_2m,precipitation_probability,weather_code,is_day"
URL+="&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset,uv_index_max"
URL+="&forecast_hours=6&forecast_days=3&timezone=auto"

stale=""
if [[ -n "$WEATHER_TEST_FILE" ]]; then # testing hook
	data=$(cat "$WEATHER_TEST_FILE")
elif data=$(curl -fsS --max-time 8 "$URL" 2>/dev/null) && jq -e '.current' <<<"$data" >/dev/null 2>&1; then
	printf '%s' "$data" >"$CACHE"
else
	data=$(cat "$CACHE" 2>/dev/null)
	stale=1
fi

if [[ -z "$data" ]] || ! jq -e '.current' <<<"$data" >/dev/null 2>&1; then
	printf '{"text":"","tooltip":"Weather unavailable","class":["offline"]}\n'
	exit 0
fi

icon() { # icon <wmo code> <is_day>
	case $1 in
	0) [[ $2 == 1 ]] && printf '%s' "$ICON_SUN" || printf '%s' "$ICON_NIGHT" ;;
	1 | 2) [[ $2 == 1 ]] && printf '%s' "$ICON_PARTLY" || printf '%s' "$ICON_NPARTLY" ;;
	3) printf '%s' "$ICON_CLOUD" ;;
	45 | 48) printf '%s' "$ICON_FOG" ;;
	51 | 53 | 55 | 56 | 57 | 61 | 80) printf '%s' "$ICON_RAINY" ;;
	63 | 65 | 66 | 67 | 81 | 82) printf '%s' "$ICON_POUR" ;;
	71 | 73 | 75 | 77 | 85 | 86) printf '%s' "$ICON_SNOW" ;;
	95 | 96 | 99) printf '%s' "$ICON_STORM" ;;
	*) printf '%s' "$ICON_CLOUD" ;;
	esac
}

desc() {
	case $1 in
	0) echo "Clear sky" ;; 1) echo "Mainly clear" ;; 2) echo "Partly cloudy" ;; 3) echo "Overcast" ;;
	45 | 48) echo "Fog" ;; 51 | 53 | 55) echo "Drizzle" ;; 56 | 57) echo "Freezing drizzle" ;;
	61) echo "Light rain" ;; 63) echo "Rain" ;; 65) echo "Heavy rain" ;; 66 | 67) echo "Freezing rain" ;;
	71 | 73 | 75 | 77) echo "Snow" ;; 80) echo "Light showers" ;; 81) echo "Showers" ;; 82) echo "Violent showers" ;;
	85 | 86) echo "Snow showers" ;; 95) echo "Thunderstorm" ;; 96 | 99) echo "Thunderstorm with hail" ;;
	*) echo "Unknown" ;;
	esac
}

kind() { # CSS class for a weather code
	case $1 in
	0 | 1 | 2) echo clear ;; 3) echo cloud ;; 45 | 48) echo fog ;;
	51 | 53 | 55 | 56 | 57 | 61 | 63 | 65 | 66 | 67 | 80 | 81 | 82) echo rain ;;
	71 | 73 | 75 | 77 | 85 | 86) echo snow ;; 95 | 96 | 99) echo storm ;; *) echo cloud ;;
	esac
}

tcol() { # colour for a temperature in °C: cool = blue/teal, warm = yellow/peach/red
	local t=$1
	if ((t >= 33)); then
		printf '%s' "$C_RED"
	elif ((t >= 30)); then
		printf '%s' "$C_PEACH"
	elif ((t >= 25)); then
		printf '%s' "$C_YELLOW"
	elif ((t >= 20)); then
		printf '%s' "$C_GREEN"
	elif ((t >= 15)); then
		printf '%s' "$C_TEAL"
	else printf '%s' "$C_SKY"; fi
}

rainbar() { # rainbar <percent>  ->  coloured 5-segment bar + percentage
	local p=$1 n i f="" e=""
	n=$(((p + 10) / 20))
	((n > 5)) && n=5
	for ((i = 0; i < n; i++)); do f+="█"; done
	for ((i = n; i < 5; i++)); do e+="░"; done
	printf "<span color='%s'>%s</span><span color='%s'>%s</span> <span color='%s'>%3s%%</span>" \
		"$C_BLUE" "$f" "$C_DIM" "$e" "$C_SUB" "$p"
}

hdr() { printf "<span size='small' weight='bold' color='%s'>%s</span>" "$C_DIM" "$1"; }
RULE="<span color='$C_DIM'>──────────────────────────</span>"

IFS=$'\t' read -r temp feels hum wind code isday \
	<<<"$(jq -r '.current | [(.temperature_2m|round), (.apparent_temperature|round), .relative_humidity_2m, (.wind_speed_10m|round), .weather_code, .is_day] | @tsv' <<<"$data")"
rain=$(jq -r '[.hourly.precipitation_probability[:4][]] | max // 0' <<<"$data")
sunrise=$(jq -r '.daily.sunrise[0] // "" | .[11:16]' <<<"$data")
sunset=$(jq -r '.daily.sunset[0] // "" | .[11:16]' <<<"$data")
uv=$(jq -r '(.daily.uv_index_max[0] // 0) | round' <<<"$data")

# ---- bar text + classes ----
text="$(icon "$code" "$isday") ${temp}°"
classes="\"$(kind "$code")\""
[[ $isday == 1 ]] && classes+=',"day"' || classes+=',"night"'
if ((rain >= RAIN_ALERT)); then
	text+=" ${rain}%"
	classes+=',"rain-likely"'
fi
[[ -n $stale ]] && classes+=',"stale"'

# ---- tooltip (Pango markup) ----
tc=$(tcol "$temp")
fc=$(tcol "$feels")
tip="<span size='large' weight='bold' color='$C_MAUVE'>$LABEL</span>"
tip+=$'\n'"<span size='xx-large' color='$tc'>$(icon "$code" "$isday")</span>  <span size='xx-large' weight='bold' color='$tc'>${temp}°</span>"
tip+=$'\n'"<span color='$C_SUB'>$(desc "$code")</span>  <span color='$C_DIM'>·</span>  <span color='$C_SUB'>feels like</span> <span color='$fc'>${feels}°</span>"
tip+=$'\n'"<span color='$C_SKY'>$ICON_HUM</span> ${hum}%    <span color='$C_TEAL'>$ICON_WIND</span> ${wind} km/h"

if [[ -n $sunrise && -n $sunset ]]; then
	uvc=$C_GREEN
	((uv >= 3)) && uvc=$C_YELLOW
	((uv >= 6)) && uvc=$C_PEACH
	((uv >= 8)) && uvc=$C_RED
	tip+=$'\n'"<span color='$C_YELLOW'>$ICON_SUNRISE</span> $sunrise   <span color='$C_PEACH'>$ICON_SUNSET</span> $sunset   <span color='$uvc'>UV $uv</span>"
fi
[[ -n $stale ]] && tip+=$'\n'"<span color='$C_PEACH'>offline: showing last update</span>"

tip+=$'\n\n'"$(hdr 'NEXT HOURS')"$'\n'"$RULE"
while IFS=$'\t' read -r t c d tp pr; do
	hc=$(tcol "$tp")
	tip+=$'\n'"<span color='$C_DIM'>$t</span>  <span color='$hc'>$(icon "$c" "$d")</span> <span color='$hc'>$(printf '%2s' "$tp")°</span>  $(rainbar "$pr")"
done < <(jq -r '. as $d | range(1; ($d.hourly.time|length)) | [$d.hourly.time[.][11:16], $d.hourly.weather_code[.], $d.hourly.is_day[.], ($d.hourly.temperature_2m[.]|round), ($d.hourly.precipitation_probability[.] // 0)] | @tsv' <<<"$data")

tip+=$'\n\n'"$(hdr 'NEXT DAYS')"$'\n'"$RULE"
n=0
while IFS=$'\t' read -r day c hi lo pr; do
	if ((n == 0)); then label="Today"; else label=$(date -d "$day" +%a 2>/dev/null || echo "$day"); fi
	hc=$(tcol "$hi")
	tip+=$'\n'"<span color='$C_SUB'>$(printf '%-5s' "$label")</span> <span color='$hc'>$(icon "$c" 1)</span> <span color='$C_SKY'>$(printf '%2s' "$lo")°</span><span color='$C_DIM'>–</span><span color='$hc'>$(printf '%2s' "$hi")°</span>  $(rainbar "$pr")"
	n=$((n + 1))
done < <(jq -r '. as $d | range(0; ($d.daily.time|length)) | [$d.daily.time[.], $d.daily.weather_code[.], ($d.daily.temperature_2m_max[.]|round), ($d.daily.temperature_2m_min[.]|round), ($d.daily.precipitation_probability_max[.] // 0)] | @tsv' <<<"$data")

jq -cn --arg text "$text" --arg tooltip "$tip" --argjson class "[$classes]" \
	'{text: $text, tooltip: $tooltip, class: $class}'
