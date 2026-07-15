#!/usr/bin/env bash
#& cron schedule: run generate_daily_report.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./utils.sh
source "$SCRIPT_DIR/utils.sh"

LOG_DIR="$SCRIPT_DIR/../logs"
CRON_TIME="${1:-0 6 * * *}"
CRON_CMD="$SCRIPT_DIR/generate_daily_report.sh >> $LOG_DIR/cron.log 2>&1"
CRON_ENTRY="$CRON_TIME $CRON_CMD"

if ! command_exists crontab; then
    log_error "crontab not found, cannot install cron job"
    exit 1
fi

if crontab -l 2>/dev/null | grep -qF "$CRON_CMD"; then
    log_warn "cron job already installed:"
    crontab -l 2>/dev/null | grep -F "$CRON_CMD"
    exit 0
fi

(crontab -l 2>/dev/null; echo "$CRON_ENTRY") | crontab -
log_info "cron job installed: $CRON_ENTRY"
log_info "usage: $0 \"<cron schedule>\" (default: \"0 6 * * *\" = daily at 6am)"
