# Simple Production Support Toolkit
> Improving Linux, Bash, SQL, and Production Support through realistic enterprise scenarios.

## Vision

**simple-prod-support-toolkit** = hands-on learning project designed to simulate the daily responsibilities in Production Support.

This repo provides a realistic production environment where every script solves an operational problem commonly encountered by support engineers.

Inspired by real enterprise application support workflows including:
- Prod health monitoring
- Incident investigation
- SQL troubleshooting
- Log analysis
- Batch job monitoring
- Db maintenance
- Linux sysadmin
- Operational automation

Full phase-by-phase roadmap: [`docs/roadmap.md`](docs/roadmap.md)

## Learning Goals

- **Linux**: navigation, permissions, processes, services, resources, file searching, log inspection, SSH, compression, cron, env vars
- **Bash**: variables, arrays, loops, functions, case statements, file processing, command substitution, exit codes, pipes, redirection, error handling
- **SQL**: SELECT, WHERE, GROUP BY, HAVING, ORDER BY, LIMIT, JOINs, aggregates, views, troubleshooting queries
- **Production Support**: reading logs, monitoring services, investigating incidents, root cause analysis, health checks, batch job monitoring, database validation, reporting

## Fake Company

**Shon Messaging Platform** — a cloud platform that delivers millions of emails and notifications every day.

```
Customers -> Campaigns -> API -> Email Service -> Database -> Logs -> Batch Jobs -> Reports
```

## Repo Structure

```
simple-prod-support-toolkit/
README.md
LICENSE
.gitignore
docs/                  architecture, roadmap, cheatsheets, incident workflow
scripts/               health checks, log analysis, incident investigation, db maintenance
sql/                   schema, seed data, operational troubleshooting queries
db/                    production.db (SQLite)
logs/                  simulated application logs
reports/               generated daily reports
archive/               compressed old logs
backups/               timestamped database backups
.github/workflows/     CI (ShellCheck, SQL validation, markdown lint)
tests/                 script tests
sample-data/           CSV seed sources
```

## Db Design (SQLite)

- **customers**: id, email, first_name, last_name, status, created_at
- **campaigns**: campaign_id, campaign_name, sending_domain, send_time
- **email_deliveries**: delivery_id, campaign_id, customer_id, status, bounce_code, delivered_at
- **bounce_events**: bounce_code, description, smtp_provider, created_at
- **batch_jobs**: job_name, status, duration, retry_count, last_run
- **audit_logs**: id, action, user, timestamp

## Running This Project

Scripts use Linux-only commands (`free`, `pgrep`, `/proc/loadavg`, `mpstat`, etc.) and will **not** run natively on macOS or Windows. Use Docker:

```bash
docker build -t prod-support-toolkit .
docker run -it --rm -v "$(pwd):/app" prod-support-toolkit
```

Then inside the container:

```bash
./scripts/health_check.sh
```

## License

[MIT](LICENSE)
