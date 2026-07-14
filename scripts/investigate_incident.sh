#!/usr/bin/env bash
#& flagship incident investigation workflow- prompts for campaign id/customer email, reads logs, runs sql, checks batch jobs, generates report

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./utils.sh
source "$SCRIPT_DIR/utils.sh"

DB_PATH="$SCRIPT_DIR/../db/production.db"
LOG_DIR="$SCRIPT_DIR/../logs"
REPORT_DIR="$SCRIPT_DIR/../reports"

read -rp "Enter Campaign ID or Customer Email: " INPUT

if [ -z "$INPUT" ]; then
    log_error "no input provided"
    exit 1
fi

TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"
SAFE_ID="$(echo "$INPUT" | tr -c 'A-Za-z0-9_-' '_')"
REPORT_FILE="$REPORT_DIR/incident_${SAFE_ID}_${TIMESTAMP}.md"

print_section "Receiving Incident"
log_info "investigating: $INPUT"

print_section "Checking Batch Jobs"
FAILED_JOBS="$(sqlite3 "$DB_PATH" "SELECT job_name || ' (' || retry_count || ' retries)' FROM batch_jobs WHERE status='failed';")"
if [ -n "$FAILED_JOBS" ]; then
    log_warn "failed batch jobs detected:"
    echo "$FAILED_JOBS"
else
    log_info "no failed batch jobs found"
fi

if [[ "$INPUT" == *"@"* ]]; then
    #~ customer email investigation
    print_section "Reading Logs"
    grep -Hin "$INPUT" "$LOG_DIR"/*.log 2>/dev/null || log_warn "no direct log matches for $INPUT"

    print_section "Running SQL"
    CUSTOMER_ROW="$(sqlite3 -separator '|' "$DB_PATH" "SELECT id, first_name, last_name, status FROM customers WHERE email='$INPUT';")"
    if [ -z "$CUSTOMER_ROW" ]; then
        log_error "no customer found for email: $INPUT"
        exit 1
    fi
    IFS='|' read -r CUSTOMER_ID FIRST_NAME LAST_NAME STATUS <<< "$CUSTOMER_ROW"

    DELIVERY_COUNT="$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM email_deliveries WHERE customer_id=$CUSTOMER_ID;")"
    BOUNCE_COUNT="$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM email_deliveries WHERE customer_id=$CUSTOMER_ID AND status='bounced';")"
    LAST_DELIVERY="$(sqlite3 "$DB_PATH" "SELECT MAX(delivered_at) FROM email_deliveries WHERE customer_id=$CUSTOMER_ID;")"

    RECOMMENDATION="No action required, continue monitoring"
    if [ "$STATUS" = "unsubscribed" ]; then
        RECOMMENDATION="Customer unsubscribed, suppress future sends"
    elif [ "$BOUNCE_COUNT" -gt 0 ]; then
        RECOMMENDATION="Validate email address, consider removing from active lists"
    fi

    print_section "Determining Root Cause"
    log_info "customer $FIRST_NAME $LAST_NAME ($STATUS) has $DELIVERY_COUNT deliveries, $BOUNCE_COUNT bounces"

    print_section "Generating Report"
    {
        echo "# Incident Report"
        echo "Customer: $FIRST_NAME $LAST_NAME <$INPUT>"
        echo "Status: $STATUS"
        echo "Total Deliveries: $DELIVERY_COUNT"
        echo "Bounces: $BOUNCE_COUNT"
        echo "Last Delivery: ${LAST_DELIVERY:-none}"
        echo "Recommendation: $RECOMMENDATION"
    } | tee "$REPORT_FILE"

else
    #~ campaign id investigation
    print_section "Reading Logs"
    grep -Hin "$INPUT" "$LOG_DIR"/*.log 2>/dev/null || log_warn "no direct log matches for $INPUT"

    print_section "Running SQL"
    RECIPIENTS="$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM email_deliveries WHERE campaign_id='$INPUT';")"
    if [ "$RECIPIENTS" -eq 0 ]; then
        log_error "no deliveries found for campaign: $INPUT"
        exit 1
    fi
    BOUNCE_RATE="$(sqlite3 "$DB_PATH" "SELECT ROUND(100.0 * SUM(CASE WHEN status='bounced' THEN 1 ELSE 0 END) / COUNT(*), 1) FROM email_deliveries WHERE campaign_id='$INPUT';")"
    TOP_BOUNCE_CODE="$(sqlite3 "$DB_PATH" "SELECT bounce_code FROM email_deliveries WHERE campaign_id='$INPUT' AND bounce_code IS NOT NULL GROUP BY bounce_code ORDER BY COUNT(*) DESC LIMIT 1;")"
    RECENT_ERRORS="$(grep -h " ERROR " "$LOG_DIR"/*.log 2>/dev/null | sed -E 's/^.* ERROR //' | sort | uniq -c | sort -rn | head -n 1 | sed -E 's/^ *[0-9]+ //')"

    print_section "Determining Root Cause"
    RECOMMENDATION="Monitor next campaign"
    if awk "BEGIN {exit !($BOUNCE_RATE > 5)}"; then
        RECOMMENDATION="Warm sending domain, retry failed jobs, monitor next campaign"
    fi
    if [ -n "$FAILED_JOBS" ]; then
        RECOMMENDATION="$RECOMMENDATION; investigate failed batch jobs"
    fi

    print_section "Generating Report"
    {
        echo "# Incident Report"
        echo "Campaign: $INPUT"
        echo "Recipients: $RECIPIENTS"
        echo "Bounce Rate: ${BOUNCE_RATE}%"
        echo "Top Bounce Code: ${TOP_BOUNCE_CODE:-none}"
        echo "Recent Errors: ${RECENT_ERRORS:-none}"
        echo "Recommendation: $RECOMMENDATION"
    } | tee "$REPORT_FILE"
fi

log_info "report saved to $REPORT_FILE"
