# Architecture

**Shon Messaging Platform**, a self-contained sandbox (Bash scripts, SQLite, Python, Flask).

## Component Overview

| Component | Location | Responsibility |
|---|---|---|
| App logs | `logs/` | Simulated app/access/error/scheduler logs, the primary input for log analysis scripts |
| Db | `db/production.db` | SQLite db holding customers, campaigns, deliveries, bounces, batch jobs, audit logs |
| Shell scripts | `scripts/*.sh` | Health checks, log analysis, batch job monitoring, db backup/restore, incident investigation |
| SQL queries | `sql/*.sql` | Standalone troubleshooting queries (bounce analysis, duplicate customers, slow queries, etc.) run against `production.db` |
| Reporting | `scripts/generate_daily_report.sh`, `scripts/generate_dashboard.py` | Aggregate system + DB state into markdown/CSV/HTML reports |
| REST API | `api/app.py` | Flask app exposing health, daily report, incident lookup, and Prometheus metrics endpoints over HTTP |
| Cron automation | `scripts/setup_cron.sh` | Schedules `generate_daily_report.sh` to run unattended, simulating a production cron job |
| Container | `Dockerfile` | Packages the whole toolkit (bash, sqlite3, cron, python3/flask) into a reproducible Linux environment |

## Data Flow

1. **Log generation** — `logs/*.log` files simulate application output (already seeded with sample data in `sample-data/`).
2. **Log analysis** — `log_summary.sh`, `top_errors.sh`, `search_logs.sh` parse these logs on demand.
3. **Db** — `sql/schema.sql` defines the schema; `sql/seed.sql` populates it. `db/production.db` is the live SQLite file scripts and the API read/write against.
4. **Monitoring scripts** — `health_check.sh`, `disk_monitor.sh`, `memory_monitor.sh`, `process_monitor.sh`, `check_batch_jobs.sh` inspect host + DB state, mimicking what a support engineer checks first during an incident.
5. **Incident investigation** — `investigate_incident.sh` ties logs + DB queries + batch job status together into a single guided workflow, producing an incident report.
6. **Reporting** — `generate_daily_report.sh` (bash) and `generate_dashboard.py` (python) roll up system + DB state into `reports/` artifacts (markdown, CSV, HTML), optionally posting a Slack summary.
7. **Automation** — `setup_cron.sh` installs a cron entry so `generate_daily_report.sh` runs on a schedule inside the container, writing to `logs/scheduler.log`.
8. **API layer** — `api/app.py` exposes the same underlying data (health, reports, incident lookup) as HTTP endpoints, plus a `/metrics` endpoint in Prometheus text-exposition format.

## Component Responsibilities (Detail)

- **`scripts/utils.sh`** — shared logging/helper functions sourced by other scripts.
- **`scripts/backup_db.sh` / `restore_db.sh`** — timestamped backup and confirmation-gated restore of `db/production.db`.
- **`scripts/archive_logs.sh`** — compresses/rotates old logs into `archive/`.
- **`api/app.py`** — reuses the same db and log files as the bash scripts; does not duplicate business logic, just exposes it over HTTP.

## Why This Structure

The separation conceptualizes a support engineer's toolbox: ad-hoc shell scripts for quick checks, SQL for data investigation, a reporting layer for stakeholders, and an API/metrics layer for integration with monitoring systems (e.g. Prometheus scraping `/metrics`). Docker + cron demonstrate how these pieces would run unattended in an actual production host.
