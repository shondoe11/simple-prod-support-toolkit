#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./utils.sh
source "$SCRIPT_DIR/utils.sh"

SERVICES=(sqlite nginx java redis python)

print_section "Process Status"
for service in "${SERVICES[@]}"; do
    pid="$(pgrep -x "$service" | head -n 1)"
    # shellcheck disable=SC2009
    if [ -n "$pid" ]; then
        log_info "$service is running (pid $pid)"
    elif ps aux | grep -v grep | grep -qi "$service"; then
        log_info "$service is running (matched via ps)"
    else
        log_warn "$service is not running"
    fi
done
