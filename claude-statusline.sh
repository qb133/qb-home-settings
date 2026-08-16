#!/bin/bash
# Usage: statusline.sh [-b] [-s style] [-w width]
#   -b: show brackets around progress bar
#   -s style: v1, v2, v3, v4 (default: v1)
#   -w width: bar width (default: 20)

STYLE="v1"
BAR_WIDTH=20
BAR_LEFT=""
BAR_RIGHT=""

while getopts "bs:w:" opt; do
    case $opt in
        b) BAR_LEFT="["; BAR_RIGHT="]" ;;
        s) STYLE="$OPTARG" ;;
        w) BAR_WIDTH="$OPTARG" ;;
    esac
done

case "$STYLE" in
    v1) FILL_CHAR='█'; EMPTY_CHAR='━' ;;
    v2) FILL_CHAR='▓'; EMPTY_CHAR='░' ;;
    v3) FILL_CHAR='⣿'; EMPTY_CHAR='⣀' ;;
    v4) FILL_CHAR='┃'; EMPTY_CHAR='╌' ;;
    *)  FILL_CHAR='█'; EMPTY_CHAR='━' ;;
esac

input=$(cat)

GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[91m'
RESET=$'\033[0m'

IFS=$'\t' read -r MODEL PCT OTOK ITOK < <(
    jq -r '[
        (.model.display_name // "?"),
        (.context_window.used_percentage // 0 | floor),
        (.context_window.total_output_tokens // 0 | floor),
        (.context_window.total_input_tokens // 0 | floor)
    ] | @tsv' <<< "$input" 2>/dev/null
)

MODEL=${MODEL:-?}
PCT=${PCT:-0}
OTOK=${OTOK:-0}
ITOK=${ITOK:-0}

FILLED=$((PCT * BAR_WIDTH / 100))
EMPTY=$((BAR_WIDTH - FILLED))
BAR=""
[ "$FILLED" -gt 0 ] && BAR=$(printf "%${FILLED}s" | tr ' ' "$FILL_CHAR")
[ "$EMPTY" -gt 0 ] && BAR="${BAR}$(printf "%${EMPTY}s" | tr ' ' "$EMPTY_CHAR")"

if [ "$PCT" -lt 50 ]; then
    BAR_COLOR="$GREEN"
elif [ "$PCT" -lt 80 ]; then
    BAR_COLOR="$YELLOW"
else
    BAR_COLOR="$RED"
fi

OUTPUT="$MODEL | i$ITOK, o$OTOK | ${BAR_LEFT}${BAR_COLOR}$BAR${RESET}${BAR_RIGHT} ${PCT}%"

if git rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git branch --show-current 2>/dev/null)
    STAGED=$(git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    MODIFIED=$(git diff --numstat 2>/dev/null | wc -l | tr -d ' ')

    GIT_STATUS=""
    [ "$STAGED" -gt 0 ] && GIT_STATUS="${GREEN}+${STAGED}${RESET}"
    [ "$MODIFIED" -gt 0 ] && GIT_STATUS="${GIT_STATUS}${YELLOW}~${MODIFIED}${RESET}"

    OUTPUT="$OUTPUT |⎇  $BRANCH $GIT_STATUS"
fi

echo -e "$OUTPUT"
