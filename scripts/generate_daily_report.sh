#!/usr/bin/env bash
#& outputs reports/daily_report.md with cpu, memory, disk, error count, failed jobs, db status, recommendations

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

DB_PATH="$SCRIPT_DIR/../db/production.db"
LOG_DIR="$SCRIPT_DIR/../logs"
REPORT_DIR="$SCRIPT_DIR/../reports"
REPORT_FILE="$REPORT_DIR/daily_report.md"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

if command_exists mpstat; then
    CPU_INFO="$(mpstat 1 1 | tail -n 1)"
else
    CPU_INFO="$(cat /proc/loadavg)"
fi

MEM_PCT="$(free | awk '/Mem:/ {printf "%.1f", ($3/$2)*100}')"

DISK_INFO="$(df -h | tail -n +2 | awk '{print $NF, $5}')"

ERROR_COUNT="$(grep -h -E " ERROR " "$LOG_DIR"/*.log 2>/dev/null | wc -l)"

FAILED_JOBS="$(sqlite3 -separator '|' "$DB_PATH" "SELECT job_name, retry_count FROM batch_jobs WHERE status='failed';" 2>/dev/null)"
FAILED_COUNT="$(echo "$FAILED_JOBS" | grep -c . || true)"

if command_exists sqlite3 && [ -f "$DB_PATH" ] && sqlite3 "$DB_PATH" "SELECT 1;" >/dev/null 2>&1; then
    DB_STATUS="reachable"
else
    DB_STATUS="unreachable"
fi

RECOMMENDATIONS=()
if awk "BEGIN {exit !($MEM_PCT > 80)}"; then
    RECOMMENDATIONS+=("Memory usage is above 80%, investigate high-memory processes")
fi
if [ "$ERROR_COUNT" -gt 5 ]; then
    RECOMMENDATIONS+=("Error count is elevated ($ERROR_COUNT), review recent logs")
fi
if [ "$FAILED_COUNT" -gt 0 ]; then
    RECOMMENDATIONS+=("$FAILED_COUNT batch job(s) failed, investigate and rerun")
fi
if [ "$DB_STATUS" = "unreachable" ]; then
    RECOMMENDATIONS+=("Database is unreachable, check connectivity immediately")
fi
if [ "${#RECOMMENDATIONS[@]}" -eq 0 ]; then
    RECOMMENDATIONS+=("No issues detected, continue routine monitoring")
fi

print_section "Generating Daily Report"

{
    echo "# Daily Report"
    echo ""
    echo "Generated: $TIMESTAMP"
    echo ""
    echo "## CPU"
    echo '```'
    echo "$CPU_INFO"
    echo '```'
    echo ""
    echo "## Memory"
    echo "Used: ${MEM_PCT}%"
    echo ""
    echo "## Disk"
    echo '```'
    echo "$DISK_INFO"
    echo '```'
    echo ""
    echo "## Errors"
    echo "Error count (current logs): $ERROR_COUNT"
    echo ""
    echo "## Failed Batch Jobs"
    if [ "$FAILED_COUNT" -gt 0 ]; then
        echo "$FAILED_JOBS" | while IFS='|' read -r job retries; do
            echo "- $job (retries: $retries)"
        done
    else
        echo "None"
    fi
    echo ""
    echo "## Database Status"
    echo "$DB_STATUS"
    echo ""
    echo "## Recommendations"
    for rec in "${RECOMMENDATIONS[@]}"; do
        echo "- $rec"
    done
} > "$REPORT_FILE"

log_info "daily report generated at $REPORT_FILE"
