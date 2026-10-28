#!/bin/bash
r=$(curl -s "https://codeforces.com/api/user.info?handles=YOUR_HANDLE" | jq '.result[0]')
echo "$(jq -r .rating <<<"$r")  max $(jq -r .maxRating <<<"$r")"
