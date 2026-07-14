#!/usr/bin/env bash
#& prints top recurring error logs

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./utils.sh
source "$SCRIPT_DIR/utils.sh"

LOG_DIR="$SCRIPT_DIR/../logs"
TOP_N="${1:-5}"

if [ "$#" -ge 2 ]; then
    TARGET_FILES=("$2")
else
    TARGET_FILES=("$LOG_DIR"/*.log)
fi

print_section "Top $TOP_N Recurring Errors"
grep -h " ERROR " "${TARGET_FILES[@]}" 2>/dev/null \
    | sed -E 's/^.* ERROR //' \
    | sort | uniq -c | sort -rn | head -n "$TOP_N" \
    | while read -r count msg; do
        log_info "$count occurrence(s): $msg"
    done
