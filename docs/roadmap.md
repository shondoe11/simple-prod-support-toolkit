# Project Roadmap

## Phase 1 — Repository Setup

**Goals**: Create project, README, folder structure, GitHub repository, MIT License.

**Learn**: Git, Markdown.

## Phase 2 — SQLite Database

**Goals**: Build schema, create realistic seed data.

**Learn**: SQL, SQLite.

## Phase 3 — Health Monitoring

**Scripts**: `health_check.sh`

Should report hostname, uptime, CPU, memory, disk, database, running services.

**Learn**: `hostname`, `uptime`, `free`, `df`, `grep`, `ps`

---

`disk_monitor.sh` — Checks disk usage, warns when usage exceeds thresholds. **Learn**: `df`, `awk`

`memory_monitor.sh` — Displays memory usage. **Learn**: `free`

`process_monitor.sh` — Checks if important services are running (sqlite, nginx, java, redis, python). **Learn**: `ps`, `grep`, `pgrep`

## Phase 4 — Log Analysis

Create realistic application logs, e.g.:

```
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

## Phase 5 — SQL Toolkit

Each SQL file answers one operational question: `campaign_summary.sql`, `duplicate_customers.sql`, `inactive_customers.sql`, `bounce_analysis.sql`, `failed_jobs.sql`, `slow_queries.sql`.

`sql_runner.sh` — `./sql_runner.sh bounce_analysis` automatically executes `sqlite3 production.db < sql/bounce_analysis.sql`

## Phase 6 — Incident Investigation (flagship feature)

`./investigate_incident.sh` prompts for Campaign ID or Customer Email.

```
Receive Incident -> Read Logs -> Run SQL -> Check Batch Jobs -> Determine Root Cause -> Generate Report
```

Example output:

```
Incident Report
Campaign: CMP-1023
Recipients: 120000
Bounce Rate: 5.1%
Top Bounce Code: 1852
Recent Errors: SMTP timeout
Recommendation: Warm sending domain, retry failed jobs, monitor next campaign
```

## Phase 7 — Batch Job Monitoring

Jobs: `customer_import`, `campaign_cleanup`, `analytics_refresh`, `nightly_backup`

`check_batch_jobs.sh` — Displays success/failed, retry count, duration.

## Phase 8 — Database Maintenance

`backup_db.sh` — Creates timestamped backups.

`restore_db.sh` — Restores backups.

**Learn**: `cp`, timestamps

## Phase 9 — Reporting

`generate_daily_report.sh` — Produces `reports/daily_report.md` including CPU, memory, disk, error count, failed jobs, database status, recommendations.

## Phase 10 — GitHub Actions

Automatically run ShellCheck, SQL validation, Markdown lint on every commit.

## Future Enhancements

- **Python**: HTML dashboard, CSV reports, Slack notifications
- **Docker**: Containerize SQLite environment
- **Cron**: Automatically run daily reports
- **REST API**: Optional Flask API exposing health/reports/incidents
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
| SQL JOIN | campaign_summary.sql |
| pipes | investigate_incident.sh |


## Success Criteria

- Confidently modify existing Bash scripts
- Write useful shell scripts from scratch
- Navigate Linux without relying on a GUI
- Investigate production issues using logs and SQL
- Explain enterprise production support workflows in interviews
- Showcase a polished GitHub repository that reflects real operational engineering practices
