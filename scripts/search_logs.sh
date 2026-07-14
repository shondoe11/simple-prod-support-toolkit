#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./utils.sh
source "$SCRIPT_DIR/utils.sh"

LOG_DIR="$SCRIPT_DIR/../logs"

if [ "$#" -lt 1 ]; then
    log_error "usage: $0 <pattern> [logfile]"
    exit 1
fi

PATTERN="$1"

if [ "$#" -ge 2 ]; then
    TARGET_FILES=("$2")
else
    TARGET_FILES=("$LOG_DIR"/*.log)
fi

print_section "Matches for '$PATTERN'"
grep -Hin "$PATTERN" "${TARGET_FILES[@]}"
