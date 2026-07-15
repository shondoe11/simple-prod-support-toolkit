# Linux Cheatsheet

## Cron (11)

- **Schedule syntax**: `minute hour day-of-month month day-of-week` — e.g. `0 6 * * *` = every day at 6:00am. `*` means "every".
- **List current jobs**: `crontab -l`
- **Install/replace all jobs**: `crontab -` reads a full new crontab from stdin, replacing the existing one entirely — so append rather than overwrite: `(crontab -l 2>/dev/null; echo "new entry") | crontab -`
- **Idempotency check**: before appending, `grep -qF` the exact command against `crontab -l` output to avoid duplicate entries on repeated runs.
- **Logging**: cron jobs run with no terminal attached and a minimal environment (no `PATH` customizations from `.bashrc`/`.zshrc`), so always redirect output explicitly, e.g. `>> logs/cron.log 2>&1`, and use absolute paths inside the script.
