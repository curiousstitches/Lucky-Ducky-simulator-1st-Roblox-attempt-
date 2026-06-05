#!/usr/bin/env bash
# push.sh - Lucky Duck one-shot deployer.
# First run asks GitHub username + repo (saved). Every run after: just commit msg + token.
# Run from inside the project folder:  bash push.sh
set -uo pipefail

# ---------------------------------------------------------------- palette
ESC=$'\033'
RESET="${ESC}[0m"
rgb(){ printf "%s[1;38;2;%s;%s;%sm" "$ESC" "$1" "$2" "$3"; }     # bold truecolor = radiant
RED="$(rgb 255 60 60)";   GREEN="$(rgb 60 230 110)"; BLUE="$(rgb 80 170 255)"
ORANGE="$(rgb 255 145 0)"; GREY="$(rgb 120 120 120)"; YELLOW="$(rgb 255 215 40)"
WATER="$(rgb 60 150 220)"; BEAK="$(rgb 255 140 0)"

ok(){     printf "%s  PASS  %s%s\n"      "$GREEN"  "$*" "$RESET"; }   # green  = good / passed
err(){    printf "%s  FAIL  %s%s\n"      "$RED"    "$*" "$RESET"; }   # red    = issues / failures
opt(){    printf "%s  OPT   %s%s\n"      "$BLUE"   "$*" "$RESET"; }   # blue   = could be optimized
sug(){    printf "%s  TYPE> %s%s\n"      "$ORANGE" "$*" "$RESET"; }   # orange = suggested text to type
filler(){ printf "%s        %s%s\n"      "$GREY"   "$*" "$RESET"; }   # grey   = filler / uncared words

# ---------------------------------------------------------------- hsv -> rgb (no subshell), full saturation
hsv(){ local h=$1 region rem; region=$((h/60)); rem=$(((h%60)*255/60))
  case $region in
    0) R=255;G=$rem;B=0;; 1) R=$((255-rem));G=255;B=0;; 2) R=0;G=255;B=$rem;;
    3) R=0;G=$((255-rem));B=255;; 4) R=$rem;G=0;B=255;; *) R=255;G=0;B=$((255-rem));; esac; }

# rainbow color-cycling radiant text (animated finale)
rainbow(){ local text="$1" cycles="${2:-16}"; local len=${#text} f i ch
  for ((f=0; f<cycles; f++)); do printf "\r"
    for ((i=0; i<len; i++)); do ch="${text:i:1}"; hsv $(((i*14 + f*22) % 360))
      printf "%s[1;38;2;%s;%s;%sm%s" "$ESC" "$R" "$G" "$B" "$ch"; done
    printf "%s" "$RESET"; sleep 0.045; done; printf "\n"; }

# ---------------------------------------------------------------- duck banner (radiant shimmer)
duck(){
  printf "\n"
  printf "%s             __%s\n"                       "$YELLOW" "$RESET"
  printf "%s           <(%so%s )___%s\n"               "$YELLOW" "$BEAK" "$YELLOW" "$RESET"
  printf "%s ~~~~~~~~~~%s( ._> /%s~~~~~~~~~~%s\n"       "$WATER"  "$YELLOW" "$WATER" "$RESET"
  printf "%s            \`---'%s\n"                     "$YELLOW" "$RESET"
  rainbow "        L U C K Y   D U C K   D E P L O Y E R" 10
  printf "\n"
}

# ---------------------------------------------------------------- config (saved once)
CONF="$HOME/.lucky-duck.conf"
duck
if [ -f "$CONF" ]; then
  # shellcheck disable=SC1090
  . "$CONF"; filler "Loaded saved profile ($GH_USER/$GH_REPO)."
else
  filler "First run - let's save your destination so you never type it again."
  printf "%s  TYPE> GitHub username: %s" "$ORANGE" "$RESET"; read -r GH_USER
  printf "%s  TYPE> Repo name: %s"       "$ORANGE" "$RESET"; read -r GH_REPO
  if [ -z "$GH_USER" ] || [ -z "$GH_REPO" ]; then err "Username and repo are required."; exit 1; fi
  printf 'GH_USER="%s"\nGH_REPO="%s"\n' "$GH_USER" "$GH_REPO" > "$CONF"
  ok "Saved profile -> $CONF"
fi

# strip any stray whitespace/CR from saved or typed identity (mobile paste guard)
GH_USER="$(printf '%s' "${GH_USER:-}" | tr -d '[:space:]')"
GH_REPO="$(printf '%s' "${GH_REPO:-}" | tr -d '[:space:]')"

# ---------------------------------------------------------------- per-push input
printf "%s  TYPE> Commit message: %s" "$ORANGE" "$RESET"; read -r MSG
[ -z "$MSG" ] && MSG="update: lucky-duck changes"
printf "%s  TYPE> GitHub token (hidden): %s" "$ORANGE" "$RESET"; read -rs TOKEN; printf "\n"
TOKEN="$(printf '%s' "$TOKEN" | tr -d '[:space:]')"   # kill trailing newline/space from paste
if [ -z "$TOKEN" ]; then err "A token is required to push."; opt "Create one: GitHub > Settings > Developer settings > Tokens (classic), scope 'repo'."; exit 1; fi

# ---------------------------------------------------------------- git pipeline
REPO_DIR="$(pwd)"
[ -f "$REPO_DIR/default.project.json" ] || filler "Heads up: running outside the project folder ($REPO_DIR)."

if [ ! -d .git ]; then git init -q && ok "Initialized git repo" || { err "git init failed"; exit 1; }; fi
git config user.name  "$GH_USER" >/dev/null 2>&1
git config user.email "${GH_USER}@users.noreply.github.com" >/dev/null 2>&1

git add -A && ok "Staged all changes" || { err "git add failed"; exit 1; }

if git diff --cached --quiet; then
  filler "Nothing new to commit - pushing current HEAD."
else
  git commit -q -m "$MSG" && ok "Committed: $MSG" || { err "git commit failed"; exit 1; }
fi

git branch -M main
git remote remove origin >/dev/null 2>&1
git remote add origin "https://github.com/${GH_USER}/${GH_REPO}.git"
opt "Token is sent as an auth header, never in the URL or git config."

AUTH="$(printf '%s:%s' "$GH_USER" "$TOKEN" | base64 | tr -d '\n')"
if git -c http.extraheader="AUTHORIZATION: basic $AUTH" push -q "https://github.com/${GH_USER}/${GH_REPO}.git" HEAD:main; then
  unset TOKEN AUTH
  rainbow "  PUSH COMPLETE - YOU'VE BEEN DUCKED  " 24
  ok "Live: https://github.com/${GH_USER}/${GH_REPO}"
else
  unset TOKEN AUTH
  err "Push rejected."
  opt "Common cause: the repo doesn't exist yet, or the token lacks 'repo' scope."
  sug "gh repo create ${GH_REPO} --private --source=. --remote=origin --push"
  exit 1
fi
