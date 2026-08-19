#!/usr/bin/env bash
# Claude Code status line.
# Usage: statusline.sh [-b] [-s style] [-w width]
#   -b: show brackets around progress bar
#   -s style: v1, v2, v3, v4 (default: v1)
#   -w width: bar width (default: 20)
#
# Portable across macOS (stock /bin/bash 3.2) and Linux/WSL (bash 5.x):
# no bash 4+ syntax, no GNU-only flags, no byte-oriented tr on UTF-8.

STYLE="v1"
BAR_WIDTH=20
BAR_LEFT=""
BAR_RIGHT=""

# ASCII digits only; rejects empty, negative, float and junk values.
is_uint() {
    case "$1" in
        ''|*[!0-9]*) return 1 ;;
        *) return 0 ;;
    esac
}

# Leading ':' silences getopts' own stderr, so a stray flag never
# corrupts the status line.
while getopts ":bs:w:" opt; do
    case $opt in
        b) BAR_LEFT="["; BAR_RIGHT="]" ;;
        s) STYLE="$OPTARG" ;;
        w) BAR_WIDTH="$OPTARG" ;;
        *) ;;
    esac
done

is_uint "$BAR_WIDTH" || BAR_WIDTH=20

case "$STYLE" in
    v1) FILL_CHAR='█'; EMPTY_CHAR='━' ;;
    v2) FILL_CHAR='▓'; EMPTY_CHAR='░' ;;
    v3) FILL_CHAR='⣿'; EMPTY_CHAR='⣀' ;;
    v4) FILL_CHAR='┃'; EMPTY_CHAR='╌' ;;
    *)  FILL_CHAR='█'; EMPTY_CHAR='━' ;;
esac

GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[91m'
RESET=$'\033[0m'

input=$(cat)

if ! command -v jq >/dev/null 2>&1; then
    printf '%s\n' "${RED}statusline: jq not found in PATH${RESET}"
    exit 0
fi

IFS=$'\t' read -r MODEL PCT OTOK ITOK < <(
    jq -r '[
        (.model.display_name // "?"),
        (.context_window.used_percentage // 0 | floor),
        (.context_window.total_output_tokens // 0 | floor),
        (.context_window.total_input_tokens // 0 | floor)
    ] | @tsv' <<< "$input" 2>/dev/null
)

# used_percentage is documented as "number | null" (null before the first
# message), and malformed JSON yields empty fields; neither may reach the
# arithmetic below.
MODEL=${MODEL:-?}
is_uint "$PCT"  || PCT=0
is_uint "$OTOK" || OTOK=0
is_uint "$ITOK" || ITOK=0
[ "$PCT" -gt 100 ] && PCT=100

FILLED=$((PCT * BAR_WIDTH / 100))
EMPTY=$((BAR_WIDTH - FILLED))
BAR=""
# Built with bash string substitution rather than tr: tr is byte-oriented
# and truncates these 3-byte UTF-8 glyphs to a single invalid 0xE2 byte.
[ "$FILLED" -gt 0 ] && { printf -v PAD "%${FILLED}s" ""; BAR="${PAD// /$FILL_CHAR}"; }
[ "$EMPTY"  -gt 0 ] && { printf -v PAD "%${EMPTY}s"  ""; BAR="${BAR}${PAD// /$EMPTY_CHAR}"; }

if [ "$PCT" -lt 50 ]; then
    BAR_COLOR="$GREEN"
elif [ "$PCT" -lt 80 ]; then
    BAR_COLOR="$YELLOW"
else
    BAR_COLOR="$RED"
fi

OUTPUT="$MODEL | i$ITOK, o$OTOK | ${BAR_LEFT}${BAR_COLOR}$BAR${RESET}${BAR_RIGHT} ${PCT}%"

# --no-optional-locks keeps this frequently-polled script from racing a real
# git command for index.lock.
if command -v git >/dev/null 2>&1 &&
   [ "$(git --no-optional-locks rev-parse --is-inside-work-tree 2>/dev/null)" = "true" ]; then
    # --show-current needs git 2.22+; fall back for older git, then to a short
    # SHA when detached, then to a marker on an unborn branch.
    BRANCH=$(git --no-optional-locks branch --show-current 2>/dev/null)
    [ -n "$BRANCH" ] || BRANCH=$(git --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)
    [ "$BRANCH" = "HEAD" ] && BRANCH=$(git --no-optional-locks rev-parse --short HEAD 2>/dev/null)
    [ -n "$BRANCH" ] || BRANCH="(no commits)"

    # BSD wc pads its count with leading spaces; strip all whitespace.
    STAGED=$(git --no-optional-locks diff --cached --numstat 2>/dev/null | wc -l | tr -d '[:space:]')
    MODIFIED=$(git --no-optional-locks diff --numstat 2>/dev/null | wc -l | tr -d '[:space:]')
    is_uint "$STAGED"   || STAGED=0
    is_uint "$MODIFIED" || MODIFIED=0

    GIT_STATUS=""
    [ "$STAGED" -gt 0 ] && GIT_STATUS="${GREEN}+${STAGED}${RESET}"
    [ "$MODIFIED" -gt 0 ] && GIT_STATUS="${GIT_STATUS}${YELLOW}~${MODIFIED}${RESET}"

    OUTPUT="$OUTPUT |⎇  $BRANCH${GIT_STATUS:+ $GIT_STATUS}"
fi

# printf, not echo -e: echo's handling of -e and backslashes varies by shell
# and by the xpg_echo setting, and branch names may contain backslashes.
printf '%s\n' "$OUTPUT"
