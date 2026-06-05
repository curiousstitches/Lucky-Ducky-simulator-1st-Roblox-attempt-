#!/usr/bin/env bash
# go.sh - Lucky Duck deployer. Rainbow on success; all-red w/ blue details on fail.
# self-guard: if launched via `sh` (dash), jump into bash so the colors work
if [ -z "$BASH_VERSION" ]; then exec bash "$0" "$@"; fi

GHUSER=curiousstitches
GHREPO=Lucky-Ducky-simulator-1st-Roblox-attempt-
TF="$HOME/.duck_token"

ESC=$'\033'; RESET="${ESC}[0m"
rgb(){ printf '%s[1;38;2;%s;%s;%sm' "$ESC" "$1" "$2" "$3"; }
RED="$(rgb 255 60 60)"; BLUE="$(rgb 90 175 255)"; YELLOW="$(rgb 255 215 40)"; WATER="$(rgb 60 150 220)"; BEAK="$(rgb 255 140 0)"

failline(){ printf '%s%s%s\n' "$RED" "$1" "$RESET"; }
faildetail(){ printf '%s  %s%s%s\n' "$RED" "$BLUE" "$1" "$RESET"; }

hsv(){ local h=$1 rem region; region=$((h/60)); rem=$(((h%60)*255/60)); case $region in
  0) R=255;G=$rem;B=0;;1) R=$((255-rem));G=255;B=0;;2) R=0;G=255;B=$rem;;
  3) R=0;G=$((255-rem));B=255;;4) R=$rem;G=0;B=255;;*) R=255;G=0;B=$((255-rem));;esac; }

rainbow(){ local text="$1"; local cycles="${2:-22}"; local len=${#text} f i ch
  for ((f=0; f<cycles; f++)); do printf '\r'
    for ((i=0; i<len; i++)); do ch="${text:i:1}"; hsv $(((i*12 + f*20) % 360))
      printf '%s[1;38;2;%s;%s;%sm%s' "$ESC" "$R" "$G" "$B" "$ch"; done
    printf '%s' "$RESET"; sleep 0.04; done; printf '\n'; }

duck_rainbow(){
  printf '\n'
  printf '%s             __%s\n' "$YELLOW" "$RESET"
  printf '%s           <(%so%s )___%s\n' "$YELLOW" "$BEAK" "$YELLOW" "$RESET"
  printf '%s ~~~~~~~~~~%s( ._> /%s~~~~~~~~~~%s\n' "$WATER" "$YELLOW" "$WATER" "$RESET"
  printf "%s            \`---'%s\n" "$YELLOW" "$RESET"
  rainbow "      *** YOU'VE BEEN DUCKED! PUSH COMPLETE ***" 26
  rainbow "        https://github.com/$GHUSER/$GHREPO" 14
  printf '\n'
}

cd "$HOME/lucky-duck-dev" || { failline "FAIL: project folder not found"; faildetail "expected: ~/lucky-duck-dev"; exit 1; }

T=""; [ -f "$TF" ] && T="$(tr -d '[:space:]' < "$TF")"
code=""; [ -n "$T" ] && code=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $T" https://api.github.com/user 2>/dev/null)
if [ "$code" != "200" ]; then
  printf '%sPaste GitHub token then Enter: %s' "$BLUE" "$RESET"; read -r T
  T="$(printf '%s' "$T" | tr -d '[:space:]')"
  code=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $T" https://api.github.com/user 2>/dev/null)
  if [ "$code" != "200" ]; then
    failline "FAIL: token rejected by GitHub"; faildetail "HTTP $code"
    faildetail "fix: new classic token, scope 'repo' -> github.com/settings/tokens/new"; exit 1
  fi
  printf '%s' "$T" > "$TF"; chmod 600 "$TF"
fi

git add -A
git commit -m "update $(date +%F_%H:%M)" >/dev/null 2>&1
AUTH="$(printf '%s:%s' "$GHUSER" "$T" | base64 | tr -d '\n')"
PUSH_ERR="$(GIT_TERMINAL_PROMPT=0 git -c http.extraheader="Authorization: Basic $AUTH" push https://github.com/$GHUSER/$GHREPO.git HEAD:main 2>&1)"
RC=$?
unset T AUTH

if [ $RC -eq 0 ]; then
  duck_rainbow
else
  failline "FAIL: push rejected"
  if printf '%s' "$PUSH_ERR" | grep -qi '403'; then faildetail "cause: token lacks 'repo' write scope"
  elif printf '%s' "$PUSH_ERR" | grep -qi 'rejected\|non-fast-forward\|fetch first'; then
    faildetail "cause: remote moved ahead of you"; faildetail "fix: tell me and I'll add a safe sync"
  elif printf '%s' "$PUSH_ERR" | grep -qi 'could not resolve\|timed out\|network'; then faildetail "cause: no internet connection"
  else faildetail "$(printf '%s' "$PUSH_ERR" | head -n1)"; fi
  exit 1
fi
