#!/usr/bin/env bash
#& info/warn/error counts output

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

LOG_DIR="$SCRIPT_DIR/../logs"

if [ "$#" -ge 1 ]; then
    TARGET_FILES=("$1")
else
    TARGET_FILES=("$LOG_DIR"/*.log)
fi

print_section "Log Summary"
for level in INFO WARN ERROR; do
    count="$(grep -h -E " ${level} " "${TARGET_FILES[@]}" 2>/dev/null | wc -l)"
    log_info "$level: $count"
done
