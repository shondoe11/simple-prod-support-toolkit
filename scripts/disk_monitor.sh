#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./utils.sh
source "$SCRIPT_DIR/utils.sh"

THRESHOLD="${1:-80}"

print_section "Disk Usage (threshold: ${THRESHOLD}%)"

df -P | tail -n +2 | while read -r filesystem _ _ _ pcent mount; do
    usage="${pcent%\%}"
    if [ "$usage" -ge "$THRESHOLD" ]; then
        log_warn "$mount is at ${usage}% usage (filesystem: $filesystem)"
    else
        log_info "$mount is at ${usage}% usage"
    fi
done
