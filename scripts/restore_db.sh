#!/usr/bin/env bash
#& restores production.db from selected backup

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

DB_PATH="$SCRIPT_DIR/../db/production.db"
BACKUP_DIR="$SCRIPT_DIR/../backups"

if [ "$#" -lt 1 ]; then
    print_section "Available Backups"
    ls -1 "$BACKUP_DIR"/*.db 2>/dev/null || log_warn "no backups found in $BACKUP_DIR"
    log_info "usage: $0 <backup_file>"
    exit 0
fi

BACKUP_FILE="$1"
if [[ "$BACKUP_FILE" != /* ]]; then
    BACKUP_FILE="$BACKUP_DIR/$BACKUP_FILE"
fi

if [ ! -f "$BACKUP_FILE" ]; then
    log_error "backup file not found: $BACKUP_FILE"
    exit 1
fi

read -rp "This will overwrite $DB_PATH with $BACKUP_FILE. Continue? [y/N] " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    log_info "restore cancelled"
    exit 0
fi

cp "$BACKUP_FILE" "$DB_PATH"
log_info "database restored from $BACKUP_FILE"
