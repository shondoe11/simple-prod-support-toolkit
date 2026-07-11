#!/usr/bin/env bash
#& compress + archive old log files

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

LOG_DIR="$SCRIPT_DIR/../logs"
ARCHIVE_DIR="$SCRIPT_DIR/../archive"
DAYS_OLD="${1:-0}"
TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"
ARCHIVE_FILE="$ARCHIVE_DIR/logs_${TIMESTAMP}.tar.gz"

FIND_ARGS=(-maxdepth 1 -name '*.log')
if [ "$DAYS_OLD" -gt 0 ]; then
    FIND_ARGS+=(-mtime "+$DAYS_OLD")
fi

mapfile -t OLD_LOGS < <(find "$LOG_DIR" "${FIND_ARGS[@]}" -printf '%f\n')

if [ "${#OLD_LOGS[@]}" -eq 0 ]; then
    log_warn "no log files older than $DAYS_OLD day(s) found in $LOG_DIR"
    exit 0
fi

tar -czf "$ARCHIVE_FILE" -C "$LOG_DIR" "${OLD_LOGS[@]}"
log_info "archived ${#OLD_LOGS[@]} log file(s) to $ARCHIVE_FILE"

for f in "${OLD_LOGS[@]}"; do
    : > "$LOG_DIR/$f"
    log_info "truncated $LOG_DIR/$f after archiving"
done
