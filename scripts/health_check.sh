#!/usr/bin/env bash
#& hostname, uptime, cpu, memory, disk, db + running services status

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

DB_PATH="$SCRIPT_DIR/../db/production.db"
SERVICES=(sqlite nginx java redis python)

print_section "Hostname"
hostname

print_section "Uptime"
uptime

print_section "CPU Load"
if command_exists mpstat; then
    mpstat 1 1
else
    cat /proc/loadavg
fi

print_section "Memory"
free -h

print_section "Disk"
df -h

print_section "Database"
if command_exists sqlite3 && [ -f "$DB_PATH" ]; then
    if sqlite3 "$DB_PATH" "SELECT 1;" >/dev/null 2>&1; then
        log_info "db reachable at $DB_PATH"
    else
        log_error "db exists but query failed at $DB_PATH"
    fi
else
    log_error "db not found at $DB_PATH"
fi

print_section "Running Services"
for service in "${SERVICES[@]}"; do
    if pgrep -x "$service" >/dev/null 2>&1; then
        log_info "$service is running"
    else
        log_warn "$service is not running"
    fi
done
