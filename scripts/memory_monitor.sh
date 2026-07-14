#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./utils.sh
source "$SCRIPT_DIR/utils.sh"

print_section "Memory Usage"
free -h

print_section "Memory Usage (% used)"
free | awk '/Mem:/ {printf "used: %.1f%%\n", ($3/$2)*100}'
