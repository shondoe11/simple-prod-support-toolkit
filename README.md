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

```text
Customers -> Campaigns -> API -> Email Service -> Database -> Logs -> Batch Jobs -> Reports
```

## Repo Structure

```text
simple-prod-support-toolkit/
README.md
LICENSE
.gitignore
docs/                  architecture, roadmap, cheatsheets, incident workflow
scripts/               health checks, log analysis, incident investigation, db maintenance
api/                   flask rest api (health/reports/incidents)
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
# 1. clone your fork
git clone https://github.com/<your-username>/simple-prod-support-toolkit.git
cd simple-prod-support-toolkit

# 2. build the image (installs sqlite3, procps, sysstat, cron, etc.)
docker build -t prod-support-toolkit .

# 3. run an interactive container, mounting the repo so file changes sync back
# (-p exposes the Flask API on localhost:5001, see REST API section below.
#  port 5001 avoids colliding with macOS AirPlay Receiver, which uses 5000)
docker run -it --rm -p 5001:5000 -v "$(pwd):/app" prod-support-toolkit
```

`db/production.db` is already committed and seeded — no setup step needed before running scripts.

Then inside the container, run any script directly:

```bash
./scripts/health_check.sh
./scripts/investigate_incident.sh
./scripts/generate_daily_report.sh
python3 scripts/generate_dashboard.py
```

`generate_dashboard.py` produces `reports/dashboard.html` and `reports/daily_report.csv` from `production.db` and `logs/`. Set `SLACK_WEBHOOK_URL` to also post a summary to Slack (stdlib only, no `pip install` required).

See [`docs/roadmap.md`](docs/roadmap.md) for the full list of scripts and what each one does.

### REST API (`api/app.py`)

Flask is pre-installed in the Docker image, not on your host — run the API from inside the container shell:

```bash
python3 api/app.py
```

Then from a separate host terminal tab (the container's shell is now occupied running Flask):

```bash
curl http://localhost:5001/health
curl http://localhost:5001/reports/daily
curl http://localhost:5001/incidents/CMP-1023
curl http://localhost:5001/incidents/jane.doe@example.com
```

If port 5001 is also taken, change the `-p 5001:5000` mapping in the `docker run` command above to any free host port.

### Testing cron (`setup_cron.sh`)

The base Ubuntu image doesn't run `cron` as a service by default. To test `setup_cron.sh` inside the container, start the daemon first:

```bash
service cron start
./scripts/setup_cron.sh
crontab -l
```

Note the container is ephemeral (`--rm`) — the installed cron job disappears when the container exits. For a persistent setup, run `setup_cron.sh` on a long-lived host or non-`--rm` container instead.

## License

[MIT](LICENSE)
