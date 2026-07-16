# Project Roadmap

## 1 — Repo Setup

**Goals**: Create project, README, folder structure, GitHub repository, MIT License.

**Learn**: Git, Markdown.

## 2 — SQLite Database

**Goals**: Build schema, create realistic seed data.

**Learn**: SQL, SQLite.

## 3 — Health Monitoring

**Scripts**: `health_check.sh`

Should report hostname, uptime, CPU, memory, disk, database, running services.

**Learn**: `hostname`, `uptime`, `free`, `df`, `grep`, `ps`

---

`disk_monitor.sh` — Checks disk usage, warns when usage exceeds thresholds. **Learn**: `df`, `awk`

`memory_monitor.sh` — Displays memory usage. **Learn**: `free`

`process_monitor.sh` — Checks if important services are running (sqlite, nginx, java, redis, python). **Learn**: `ps`, `grep`, `pgrep`

## 4 — Log Analysis

Create realistic application logs, e.g.:

```text
INFO Starting application
INFO Database connected
WARN Slow query
ERROR SMTP timeout
ERROR Connection refused
INFO Retry successful
```

`log_summary.sh` — Outputs INFO/WARN/ERROR counts. **Learn**: `grep`, `wc`

`top_errors.sh` — Outputs top recurring errors. **Learn**: `sort`, `uniq`, `awk`

`search_logs.sh` — `./search_logs.sh ERROR` returns every matching line. **Learn**: `grep`

`archive_logs.sh` — Compresses old logs. **Learn**: `tar`, `gzip`, `find`

## 5 — SQL Toolkit

Each SQL file answers one operational question: `campaign_summary.sql`, `duplicate_customers.sql`, `inactive_customers.sql`, `bounce_analysis.sql`, `failed_jobs.sql`, `slow_queries.sql`.

`sql_runner.sh` — `./sql_runner.sh bounce_analysis` automatically executes `sqlite3 production.db < sql/bounce_analysis.sql`

## 6 — Incident Investigation (flagship feature)

`./investigate_incident.sh` prompts for Campaign ID or Customer Email.

```text
Receive Incident -> Read Logs -> Run SQL -> Check Batch Jobs -> Determine Root Cause -> Generate Report
```

Example output:

```text
Incident Report
Campaign: CMP-1023
Recipients: 120000
Bounce Rate: 5.1%
Top Bounce Code: 1852
Recent Errors: SMTP timeout
Recommendation: Warm sending domain, retry failed jobs, monitor next campaign
```

## 7 — Batch Job Monitoring

Jobs: `customer_import`, `campaign_cleanup`, `analytics_refresh`, `nightly_backup`

`check_batch_jobs.sh` — Displays success/failed, retry count, duration.

## 8 — Database Maintenance

`backup_db.sh` — Creates timestamped backups.

`restore_db.sh` — Restores backups.

**Learn**: `cp`, timestamps

## 9 — Reporting

`generate_daily_report.sh` — Produces `reports/daily_report.md` including CPU, memory, disk, error count, failed jobs, database status, recommendations.

## 10 — GitHub Actions

Automatically run ShellCheck, SQL validation, Markdown lint on every commit.

## 11 — Cron Automation

`setup_cron.sh` — Installs a cron job to run `generate_daily_report.sh` on a schedule (default: daily at 6am). Idempotent — checks for an existing entry before appending.

**Learn**: `crontab`, cron schedule syntax

## 12 — Python Reporting Enhancements

`generate_dashboard.py` — Reads `production.db` and `logs/`, produces `reports/dashboard.html` (styled dashboard) and `reports/daily_report.csv` (structured metrics). Posts a summary to Slack via incoming webhook if `SLACK_WEBHOOK_URL` is set (stdlib only, no extra dependencies).

**Learn**: Python `sqlite3`, `csv`, `urllib.request`, `html.escape`

## 13 — REST API

`api/app.py` — Flask API exposing `/health` (hostname, uptime, memory, disk, db status, running services), `/reports/daily` (error count, failed jobs, db status, recommendations — reuses `generate_dashboard.py` logic), and `/incidents/<identifier>` (campaign ID or customer email investigation, mirroring `investigate_incident.sh`). Returns JSON; 404s return JSON errors via a custom error handler.

**Learn**: Flask routing, JSON responses, parameterized SQL queries, custom error handlers

## Future Enhancements

- **Monitoring**: Simulate Prometheus metrics

## Dev Workflow

Each concept to become a feature:

| Learned | Implement |
|----------|-----------|
| Variables | health_check.sh |
| if statements | disk_monitor.sh |
| loops | archive_logs.sh |
| functions | utils.sh |
| grep | search_logs.sh |
| awk | top_errors.sh |
| sed | log_cleanup.sh |
| find | archive_logs.sh |
| Python sqlite3/csv | generate_dashboard.py |
| Flask routing | api/app.py |
| SQL JOIN | campaign_summary.sql |
| pipes | investigate_incident.sh |

## Success Criteria

- Confidently modify existing Bash scripts
- Write useful shell scripts from scratch
- Navigate Linux without relying on a GUI
- Investigate production issues using logs and SQL
- Explain enterprise production support workflows in interviews
- Showcase a polished GitHub repository that reflects real operational engineering practices
