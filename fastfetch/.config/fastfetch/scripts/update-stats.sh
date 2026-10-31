#!/bin/bash
# Refreshes ~/.cache/fastfetch/* (run hourly by the systemd timer)
# Needs UTF-8 so printf can expand \u icon escapes (systemd runs in the C locale)
export LC_ALL=C.UTF-8

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/fastfetch"
GH_USER="ttylanre"
AL_USER="ttylanre"
mkdir -p "$CACHE"

# Optional: put a GitHub token in this file for higher rate limits (and private repo counts)
AUTH=()
TOKEN_FILE="$HOME/.config/fastfetch/gh_token"
[ -r "$TOKEN_FILE" ] && AUTH=(-H "Authorization: Bearer $(<"$TOKEN_FILE")")

# Write atomically, and only if we got something, so a failed fetch keeps the old value
save() {
	[ -n "$2" ] || return 1
	printf '%s\n' "$2" >"$CACHE/$1.tmp" && mv "$CACHE/$1.tmp" "$CACHE/$1"
}

get() { curl -fsS --max-time 10 "${AUTH[@]}" "$@"; }

ago() {
	local s=$(($(date +%s) - $(date -d "$1" +%s))) || return 1
	if [ "$s" -lt 3600 ]; then
		echo "$((s / 60))m ago"
	elif [ "$s" -lt 86400 ]; then
		echo "$((s / 3600))h ago"
	elif [ "$s" -lt 2592000 ]; then
		echo "$((s / 86400))d ago"
	else echo "$((s / 2592000))mo ago"; fi
}

# ---------- GitHub: profile numbers ----------
gh_profile() {
	local n f s k
	# Feed big JSON through stdin: --argjson would hit the OS argument size limit (~128 KB)
	read -r n f < <(jq -r '"\(.public_repos) \(.followers)"' <<<"$user")
	read -r s k < <(jq -r '"\(map(.stargazers_count) | add // 0) \(map(select(.fork | not) | .forks_count) | add // 0)"' <<<"$repos")
	[ -n "$n" ] && [ -n "$f" ] && [ -n "$s" ] && [ -n "$k" ] || return 1
	printf '\uf401 %s  \uf0c0 %s  \uf005 %s  \uf126 %s' "$n" "$f" "$s" "$k"
}

# ---------- GitHub: top languages by repo count (own repos, forks excluded) ----------
gh_langs() {
	jq -r '
    [.[] | select(.fork == false and .language != null) | .language] as $l
    | ($l | length) as $t
    | if $t == 0 then empty else
        ($l | group_by(.) | map({n: .[0], c: length}) | sort_by(-.c) | .[:4]
         | map("\(.n) \(.c * 100 / $t | round)%") | join("  ·  "))
      end' <<<"$repos"
}

# ---------- GitHub: most recently pushed repo ----------
gh_lastpush() {
	local name pushed
	read -r name pushed < <(jq -r '.[0] | "\(.name) \(.pushed_at)"' <<<"$repos")
	[ -n "$name" ] && [ "$name" != "null" ] || return 1
	printf '%s  ·  %s' "$name" "$(ago "$pushed")"
}

# ---------- GitHub: contributions (14-day sparkline, total, streak) ----------
# Uses the public github-contributions-api (third party, no token needed)
gh_activity() {
	local act out total streak spark
	act=$(curl -fsS --max-time 15 "https://github-contributions-api.jogruber.de/v4/$GH_USER?y=last") || return 1
	out=$(jq -r --arg today "$(date +%F)" '
    [.contributions[] | select(.date <= $today)] as $d
    | ($d | map(.count) | add // 0) as $total
    | ($d | reverse) as $r
    | (if ($r[0].count // 0) == 0 then $r[1:] else $r end) as $s
    | (reduce $s[] as $x ({n: 0, stop: false};
         if .stop then . elif $x.count > 0 then .n += 1 else .stop = true end) | .n) as $streak
    | ($d | .[-14:] | map(.count)) as $c
    | ($c | max // 0) as $m
    | ($c | map(if . == 0 or $m == 0 then "▁"
                else ["▁","▂","▃","▄","▅","▆","▇","█"][. / $m * 7 | ceil] end) | join("")) as $spark
    | "\($total)\t\($streak)\t\($spark)"' <<<"$act") || return 1
	IFS=$'\t' read -r total streak spark <<<"$out"
	[ -n "$spark" ] || return 1
	printf '%s  %s this year  \uf06d %s days' "$spark" "$total" "$streak"
}

# ---------- AniList ----------
anilist() {
	local j a e m c
	j=$(curl -fsS --max-time 10 https://graphql.anilist.co -H 'Content-Type: application/json' \
		-d "{\"query\":\"{User(name:\\\"$AL_USER\\\"){statistics{anime{count episodesWatched} manga{count chaptersRead}}}}\"}") || return 1
	read -r a e m c < <(jq -r '.data.User.statistics | "\(.anime.count) \(.anime.episodesWatched) \(.manga.count) \(.manga.chaptersRead)"' <<<"$j")
	[ -n "$a" ] && [ "$a" != "null" ] || return 1
	printf '\uf26c %s  \uf04b %s  \uf02d %s  \uf06e %s' "$a" "$e" "$m" "$c"
}

# ---------- run everything; any failure just keeps the old cached value ----------
if user=$(get "https://api.github.com/users/$GH_USER") &&
	repos=$(get "https://api.github.com/users/$GH_USER/repos?per_page=100&sort=pushed&direction=desc") &&
	[ -n "$(jq -r '.public_repos // empty' <<<"$user")" ]; then
	out=$(gh_profile) && save github "$out"
	out=$(gh_langs) && save langs "$out"
	out=$(gh_lastpush) && save lastpush "$out"
fi
out=$(gh_activity) && save activity "$out"
out=$(anilist) && save anilist "$out"
exit 0
