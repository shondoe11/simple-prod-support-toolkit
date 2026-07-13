#!/usr/bin/env bash
#& prints batch job success/failure, retry count, duration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

DB_PATH="$SCRIPT_DIR/../db/production.db"
JOBS=(customer_import campaign_cleanup analytics_refresh nightly_backup)

print_section "Batch Job Status (most recent run)"
for job in "${JOBS[@]}"; do
    ROW="$(sqlite3 -separator '|' "$DB_PATH" "SELECT status, duration, retry_count, last_run FROM batch_jobs WHERE job_name='$job' ORDER BY last_run DESC LIMIT 1;")"
    if [ -z "$ROW" ]; then
        log_warn "$job: no run history found"
        continue
    fi
    IFS='|' read -r STATUS DURATION RETRY_COUNT LAST_RUN <<< "$ROW"
    case "$STATUS" in
        success)
            log_info "$job: success (duration ${DURATION}s, retries $RETRY_COUNT, last run $LAST_RUN)"
            ;;
        failed)
            log_error "$job: failed (duration ${DURATION}s, retries $RETRY_COUNT, last run $LAST_RUN)"
            ;;
        running)
            log_warn "$job: currently running (started $LAST_RUN)"
            ;;
        *)
            log_warn "$job: unknown status '$STATUS'"
            ;;
    esac
done
