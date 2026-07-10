#!/usr/bin/env bash
#& reusable helper funcs

log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*"
}

log_warn() {
    echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') - $*"
}

#~ err-level log line. timestamp to stderr
log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
}

#~ header for readability
print_section() {
    echo ""
    echo "== $* =="
}

#~ simple command lookup
command_exists() {
    command -v "$1" >/dev/null 2>&1
}
