#!/bin/bash
# Needs UTF-8 so printf can expand \u icon escapes (systemd services often run in the C locale)
export LC_ALL=C.UTF-8

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/fastfetch"
GH_USER="ttylanre"
AL_USER="ttylanre"
mkdir -p "$CACHE"

# Write atomically, and only if we got something, so a failed fetch keeps the old value
save() {
	[ -n "$2" ] || return 1
	printf '%s\n' "$2" >"$CACHE/$1.tmp" && mv "$CACHE/$1.tmp" "$CACHE/$1"
}

github() {
	local d stars repos
	d=$(curl -fsS --max-time 10 "https://api.github.com/users/$GH_USER") || return 1
	repos=$(jq -r .public_repos <<<"$d")
	[ "$repos" != "null" ] || return 1 # rate-limited or error response
	stars=$(curl -fsS --max-time 10 "https://api.github.com/users/$GH_USER/repos?per_page=100" |
		jq '[.[].stargazers_count] | add // 0') || stars=0
	printf '\uf401 %s  \uf0c0 %s  \uf005 %s' "$repos" "$(jq -r .followers <<<"$d")" "$stars"
}

anilist() {
	local j a e m c
	j=$(curl -fsS --max-time 10 https://graphql.anilist.co -H 'Content-Type: application/json' \
		-d "{\"query\":\"{User(name:\\\"$AL_USER\\\"){statistics{anime{count episodesWatched} manga{count chaptersRead}}}}\"}") || return 1
	read -r a e m c < <(jq -r '.data.User.statistics | "\(.anime.count) \(.anime.episodesWatched) \(.manga.count) \(.manga.chaptersRead)"' <<<"$j")
	[ -n "$a" ] && [ "$a" != "null" ] || return 1
	printf '\uf26c %s  \uf04b %s  \uf02d %s  \uf06e %s' "$a" "$e" "$m" "$c"
}

out=$(github) && save github "$out"
out=$(anilist) && save anilist "$out"
exit 0
