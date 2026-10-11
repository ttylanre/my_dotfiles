#!/usr/bin/env bash
# Waybar weather module (Open-Meteo: free, no API key).
# Requires: curl, jq
# Output: JSON for waybar (return-type json) with an icon + temperature,
# a rich tooltip, and CSS classes (clear/cloud/rain/storm/fog/snow, day/night,
# rain-likely, offline). Caches the last good result for offline use.

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

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/waybar-weather.json"
mkdir -p "$(dirname "$CACHE")"

URL="https://api.open-meteo.com/v1/forecast?latitude=${LAT}&longitude=${LON}"
URL+="&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m,is_day"
URL+="&hourly=temperature_2m,precipitation_probability,weather_code,is_day"
URL+="&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max"
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

IFS=$'\t' read -r temp feels hum wind code isday \
	<<<"$(jq -r '.current | [(.temperature_2m|round), (.apparent_temperature|round), .relative_humidity_2m, (.wind_speed_10m|round), .weather_code, .is_day] | @tsv' <<<"$data")"
rain=$(jq -r '[.hourly.precipitation_probability[:4][]] | max // 0' <<<"$data")

text="$(icon "$code" "$isday") ${temp}°"
classes="\"$(kind "$code")\""
[[ $isday == 1 ]] && classes+=',"day"' || classes+=',"night"'
if ((rain >= RAIN_ALERT)); then
	text+=" ${rain}%"
	classes+=',"rain-likely"'
fi
[[ -n $stale ]] && classes+=',"stale"'

tip="$LABEL"$'\n'"$(desc "$code") · feels like ${feels}°"$'\n'"Humidity ${hum}% · Wind ${wind} km/h"
[[ -n $stale ]] && tip+=$'\n(offline: showing last update)'

tip+=$'\n\nNext hours'
while IFS=$'\t' read -r t c d tp pr; do
	tip+=$'\n'"$t  $(icon "$c" "$d") ${tp}°  ${pr}%"
done < <(jq -r '. as $d | range(1; ($d.hourly.time|length)) | [$d.hourly.time[.][11:16], $d.hourly.weather_code[.], $d.hourly.is_day[.], ($d.hourly.temperature_2m[.]|round), ($d.hourly.precipitation_probability[.] // 0)] | @tsv' <<<"$data")

tip+=$'\n\nNext days'
n=0
while IFS=$'\t' read -r day c hi lo pr; do
	if ((n == 0)); then label="Today"; else label=$(date -d "$day" +%a 2>/dev/null || echo "$day"); fi
	tip+=$'\n'"$(printf '%-5s' "$label") $(icon "$c" 1) ${lo}°–${hi}°  ${pr}%"
	n=$((n + 1))
done < <(jq -r '. as $d | range(0; ($d.daily.time|length)) | [$d.daily.time[.], $d.daily.weather_code[.], ($d.daily.temperature_2m_max[.]|round), ($d.daily.temperature_2m_min[.]|round), ($d.daily.precipitation_probability_max[.] // 0)] | @tsv' <<<"$data")

jq -cn --arg text "$text" --arg tooltip "$tip" --argjson class "[$classes]" \
	'{text: $text, tooltip: $tooltip, class: $class}'
