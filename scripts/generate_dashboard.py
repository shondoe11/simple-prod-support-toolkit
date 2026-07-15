#!/usr/bin/env python3
#& generates reports/dashboard.html + reports/daily_report.csv from production.db and logs
#~ optionally posts summary slack if $SLACK_WEBHOOK_URL is set

import csv
import glob
import json
import os
import re
import sqlite3
import sys
import urllib.request
from datetime import datetime
from html import escape

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(SCRIPT_DIR, "..", "db", "production.db")
LOG_DIR = os.path.join(SCRIPT_DIR, "..", "logs")
REPORT_DIR = os.path.join(SCRIPT_DIR, "..", "reports")
HTML_FILE = os.path.join(REPORT_DIR, "dashboard.html")
CSV_FILE = os.path.join(REPORT_DIR, "daily_report.csv")


#~ count of lines matching " ERROR " across all *.log files in log_dir
def count_errors(log_dir):
    pattern = re.compile(r" ERROR ")
    count = 0
    for path in glob.glob(os.path.join(log_dir, "*.log")):
        with open(path, "r", errors="ignore") as f:
            for line in f:
                if pattern.search(line):
                    count += 1
    return count


#~ queries batch_jobs for rows with status='failed', returns list of (job_name, retry_count)
def get_failed_jobs(db_path):
    if not os.path.isfile(db_path):
        return None
    try:
        conn = sqlite3.connect(db_path)
        cur = conn.cursor()
        cur.execute("SELECT job_name, retry_count FROM batch_jobs WHERE status='failed';")
        rows = cur.fetchall()
        conn.close()
        return rows
    except sqlite3.Error:
        return None


#~ checks db is reachable using simple query
def get_db_status(db_path):
    if not os.path.isfile(db_path):
        return "unreachable"
    try:
        conn = sqlite3.connect(db_path)
        conn.execute("SELECT 1;")
        conn.close()
        return "reachable"
    except sqlite3.Error:
        return "unreachable"


def build_recommendations(error_count, failed_jobs, db_status):
    recs = []
    if error_count > 5:
        recs.append(f"Error count is elevated ({error_count}), review recent logs")
    if failed_jobs:
        recs.append(f"{len(failed_jobs)} batch job(s) failed, investigate and rerun")
    if db_status == "unreachable":
        recs.append("Database is unreachable, check connectivity immediately")
    if not recs:
        recs.append("No issues detected, continue routine monitoring")
    return recs


def write_csv(path, timestamp, error_count, failed_jobs, db_status):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["metric", "value"])
        writer.writerow(["generated", timestamp])
        writer.writerow(["error_count", error_count])
        writer.writerow(["failed_job_count", len(failed_jobs) if failed_jobs else 0])
        writer.writerow(["db_status", db_status])
        for job_name, retry_count in (failed_jobs or []):
            writer.writerow([f"failed_job:{job_name}", retry_count])


def write_html(path, timestamp, error_count, failed_jobs, db_status, recommendations):
    failed_rows = "".join(
        f"<tr><td>{escape(job)}</td><td>{retries}</td></tr>"
        for job, retries in (failed_jobs or [])
    ) or "<tr><td colspan='2'>None</td></tr>"

    rec_items = "".join(f"<li>{escape(r)}</li>" for r in recommendations)

    status_class = "ok" if db_status == "reachable" else "bad"

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Daily Report Dashboard</title>
<style>
    body {{ font-family: -apple-system, Arial, sans-serif; background: #0f172a; color: #e2e8f0; margin: 0; padding: 2rem; }}
    h1 {{ font-size: 1.5rem; margin-bottom: 0.25rem; }}
    .timestamp {{ color: #94a3b8; margin-bottom: 1.5rem; }}
    .cards {{ display: flex; gap: 1rem; flex-wrap: wrap; margin-bottom: 1.5rem; }}
    .card {{ background: #1e293b; border-radius: 8px; padding: 1rem 1.5rem; min-width: 160px; }}
    .card .label {{ color: #94a3b8; font-size: 0.8rem; text-transform: uppercase; }}
    .card .value {{ font-size: 1.8rem; font-weight: bold; }}
    .ok {{ color: #4ade80; }}
    .bad {{ color: #f87171; }}
    table {{ width: 100%; border-collapse: collapse; margin-bottom: 1.5rem; }}
    th, td {{ text-align: left; padding: 0.5rem; border-bottom: 1px solid #334155; }}
    ul {{ padding-left: 1.2rem; }}
</style>
</head>
<body>
    <h1>Daily Report Dashboard</h1>
    <div class="timestamp">Generated: {escape(timestamp)}</div>

    <div class="cards">
    <div class="card"><div class="label">Error Count</div><div class="value">{error_count}</div></div>
    <div class="card"><div class="label">Failed Jobs</div><div class="value">{len(failed_jobs) if failed_jobs else 0}</div></div>
    <div class="card"><div class="label">Database</div><div class="value {status_class}">{escape(db_status)}</div></div>
    </div>

    <h2>Failed Batch Jobs</h2>
    <table>
    <thead><tr><th>Job</th><th>Retries</th></tr></thead>
    <tbody>{failed_rows}</tbody>
    </table>

    <h2>Recommendations</h2>
    <ul>{rec_items}</ul>
</body>
</html>
"""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(html)


#~ post plain-text summary to slack via incoming webhook, if isConfigured
def notify_slack(timestamp, error_count, failed_jobs, db_status, recommendations):
    webhook_url = os.environ.get("SLACK_WEBHOOK_URL")
    if not webhook_url:
        print("[INFO] SLACK_WEBHOOK_URL not set, skipping slack notification")
        return

    lines = [
        f"*Daily Report* — {timestamp}",
        f"Errors: {error_count} | Failed Jobs: {len(failed_jobs) if failed_jobs else 0} | DB: {db_status}",
    ]
    lines.extend(f"- {r}" for r in recommendations)
    payload = json.dumps({"text": "\n".join(lines)}).encode("utf-8")

    req = urllib.request.Request(
        webhook_url, data=payload, headers={"Content-Type": "application/json"}
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            print(f"[INFO] slack notification sent (status {resp.status})")
    except Exception as exc:
        print(f"[WARN] slack notification failed: {exc}", file=sys.stderr)


def main():
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    error_count = count_errors(LOG_DIR)
    failed_jobs = get_failed_jobs(DB_PATH)
    db_status = get_db_status(DB_PATH)
    recommendations = build_recommendations(error_count, failed_jobs, db_status)

    write_csv(CSV_FILE, timestamp, error_count, failed_jobs, db_status)
    write_html(HTML_FILE, timestamp, error_count, failed_jobs, db_status, recommendations)
    notify_slack(timestamp, error_count, failed_jobs, db_status, recommendations)

    print(f"[INFO] dashboard generated at {HTML_FILE}")
    print(f"[INFO] csv report generated at {CSV_FILE}")


if __name__ == "__main__":
    main()
