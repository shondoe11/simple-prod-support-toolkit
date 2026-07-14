#!/usr/bin/env bash
#& production.db backup with timestamp

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./utils.sh
source "$SCRIPT_DIR/utils.sh"

DB_PATH="$SCRIPT_DIR/../db/production.db"
BACKUP_DIR="$SCRIPT_DIR/../backups"
TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"
BACKUP_FILE="$BACKUP_DIR/production_${TIMESTAMP}.db"

if [ ! -f "$DB_PATH" ]; then
    log_error "database not found at $DB_PATH"
    exit 1
fi

cp "$DB_PATH" "$BACKUP_FILE"
log_info "backup created: $BACKUP_FILE"
