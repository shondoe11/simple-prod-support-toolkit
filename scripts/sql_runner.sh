#!/usr/bin/env bash
#& runs against production.db

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

DB_PATH="$SCRIPT_DIR/../db/production.db"
SQL_DIR="$SCRIPT_DIR/../sql"

if [ "$#" -lt 1 ]; then
    log_error "usage: $0 <query_name>"
    log_info "available queries:"
    for f in "$SQL_DIR"/*.sql; do
        name="$(basename "$f" .sql)"
        case "$name" in
            schema|seed) continue ;;
        esac
        echo "  - $name"
    done
    exit 1
fi

QUERY_NAME="$1"
QUERY_FILE="$SQL_DIR/${QUERY_NAME}.sql"

if [ ! -f "$QUERY_FILE" ]; then
    log_error "no such query file: $QUERY_FILE"
    exit 1
fi

if [ ! -f "$DB_PATH" ]; then
    log_error "database not found at $DB_PATH"
    exit 1
fi

print_section "Running $QUERY_NAME"
sqlite3 -header -column "$DB_PATH" < "$QUERY_FILE"
