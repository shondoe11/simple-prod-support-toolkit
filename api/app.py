#!/usr/bin/env python3
#& flask rest api exposing health/reports/incidents endpoints
#~ run: python3 api/app.py (req linux env, see docker setup in readme)

import glob
import os
import re
import sqlite3
import subprocess
import sys

from flask import Flask, Response, abort, jsonify

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "..", "db", "production.db")
LOG_DIR = os.path.join(BASE_DIR, "..", "logs")
SCRIPTS_DIR = os.path.join(BASE_DIR, "..", "scripts")
sys.path.insert(0, SCRIPTS_DIR)

app = Flask(__name__)


#~ runs query on production.db, return format: list of dicts
def query_db(sql, params=()):
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()
    cur.execute(sql, params)
    rows = [dict(r) for r in cur.fetchall()]
    conn.close()
    return rows


#~ runs sys command, return stdout (/ err string on failure)
def run_cmd(cmd):
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
        return result.stdout.strip()
    except Exception as exc:
        return f"error: {exc}"


#~ find most frequent " ERROR <message>" text on all log files
def get_top_error(log_dir):
    pattern = re.compile(r" ERROR (.*)")
    counts = {}
    for path in glob.glob(os.path.join(log_dir, "*.log")):
        with open(path, "r", errors="ignore") as f:
            for line in f:
                match = pattern.search(line)
                if match:
                    msg = match.group(1).strip()
                    counts[msg] = counts.get(msg, 0) + 1
    if not counts:
        return None
    return max(counts.items(), key=lambda kv: kv[1])[0]


#~ which monitored service processes running
def get_running_services():
    services = ["sqlite", "nginx", "java", "redis", "python"]
    running = {}
    for service in services:
        result = subprocess.run(["pgrep", "-x", service], capture_output=True)
        running[service] = result.returncode == 0
    return running


#~ find log lines containing identifier (case-insensitive), used by /incidents
def search_logs(log_dir, identifier):
    pattern = re.compile(re.escape(identifier), re.IGNORECASE)
    matches = []
    for path in glob.glob(os.path.join(log_dir, "*.log")):
        with open(path, "r", errors="ignore") as f:
            for line_num, line in enumerate(f, start=1):
                if pattern.search(line):
                    matches.append(
                        {"file": os.path.basename(path), "line": line_num, "text": line.strip()}
                    )
    return matches


@app.errorhandler(404)
def not_found(err):
    return jsonify({"error": str(err.description)}), 404


@app.route("/health")
def health():
    running = get_running_services()

    db_status = "unreachable"
    if os.path.isfile(DB_PATH):
        try:
            conn = sqlite3.connect(DB_PATH)
            conn.execute("SELECT 1;")
            conn.close()
            db_status = "reachable"
        except sqlite3.Error:
            pass

    return jsonify(
        {
            "hostname": run_cmd(["hostname"]),
            "uptime": run_cmd(["uptime"]),
            "memory": run_cmd(["free", "-h"]),
            "disk": run_cmd(["df", "-h"]),
            "database": db_status,
            "services": running,
        }
    )


@app.route("/reports/daily")
def reports_daily():
    from generate_dashboard import build_recommendations, count_errors, get_db_status, get_failed_jobs

    error_count = count_errors(LOG_DIR)
    failed_jobs = get_failed_jobs(DB_PATH) or []
    db_status = get_db_status(DB_PATH)
    recommendations = build_recommendations(error_count, failed_jobs, db_status)

    return jsonify(
        {
            "error_count": error_count,
            "failed_jobs": [{"job_name": j, "retry_count": r} for j, r in failed_jobs],
            "db_status": db_status,
            "recommendations": recommendations,
        }
    )


@app.route("/metrics")
def metrics():
    from generate_dashboard import count_errors, get_db_status, get_failed_jobs

    error_count = count_errors(LOG_DIR)
    failed_jobs = get_failed_jobs(DB_PATH) or []
    db_status = get_db_status(DB_PATH)
    services = get_running_services()

    lines = [
        "# HELP app_error_count Total ERROR lines found in logs/*.log",
        "# TYPE app_error_count gauge",
        f"app_error_count {error_count}",
        "# HELP app_failed_jobs_total Number of batch jobs currently in failed status",
        "# TYPE app_failed_jobs_total gauge",
        f"app_failed_jobs_total {len(failed_jobs)}",
        "# HELP app_batch_job_retry_count Retry count per failed batch job",
        "# TYPE app_batch_job_retry_count gauge",
    ]
    for job_name, retry_count in failed_jobs:
        lines.append(f'app_batch_job_retry_count{{job_name="{job_name}"}} {retry_count}')

    lines += [
        "# HELP app_db_up Whether production.db is reachable (1) or not (0)",
        "# TYPE app_db_up gauge",
        f"app_db_up {1 if db_status == 'reachable' else 0}",
        "# HELP app_service_up Whether a monitored service process is running (1) or not (0)",
        "# TYPE app_service_up gauge",
    ]
    for service, is_running in services.items():
        lines.append(f'app_service_up{{service="{service}"}} {1 if is_running else 0}')

    return Response("\n".join(lines) + "\n", mimetype="text/plain; version=0.0.4; charset=utf-8")


@app.route("/incidents/<identifier>")
def incidents(identifier):
    failed_jobs = query_db("SELECT job_name, retry_count FROM batch_jobs WHERE status='failed';")
    log_matches = search_logs(LOG_DIR, identifier)

    if "@" in identifier:
        rows = query_db(
            "SELECT id, first_name, last_name, status FROM customers WHERE email=?;", (identifier,)
        )
        if not rows:
            abort(404, description=f"no customer found for email: {identifier}")
        customer = rows[0]
        customer_id = customer["id"]

        delivery_count = query_db(
            "SELECT COUNT(*) AS c FROM email_deliveries WHERE customer_id=?;", (customer_id,)
        )[0]["c"]
        bounce_count = query_db(
            "SELECT COUNT(*) AS c FROM email_deliveries WHERE customer_id=? AND status='bounced';",
            (customer_id,),
        )[0]["c"]
        last_delivery = query_db(
            "SELECT MAX(delivered_at) AS m FROM email_deliveries WHERE customer_id=?;", (customer_id,)
        )[0]["m"]

        recommendation = "No action required, continue monitoring"
        if customer["status"] == "unsubscribed":
            recommendation = "Customer unsubscribed, suppress future sends"
        elif bounce_count > 0:
            recommendation = "Validate email address, consider removing from active lists"

        return jsonify(
            {
                "type": "customer",
                "identifier": identifier,
                "customer": customer,
                "delivery_count": delivery_count,
                "bounce_count": bounce_count,
                "last_delivery": last_delivery,
                "failed_batch_jobs": failed_jobs,
                "log_matches": log_matches,
                "recommendation": recommendation,
            }
        )

    recipients = query_db(
        "SELECT COUNT(*) AS c FROM email_deliveries WHERE campaign_id=?;", (identifier,)
    )[0]["c"]
    if recipients == 0:
        abort(404, description=f"no deliveries found for campaign: {identifier}")

    bounce_rate = query_db(
        "SELECT ROUND(100.0 * SUM(CASE WHEN status='bounced' THEN 1 ELSE 0 END) / COUNT(*), 1) AS r "
        "FROM email_deliveries WHERE campaign_id=?;",
        (identifier,),
    )[0]["r"]
    top_bounce_rows = query_db(
        "SELECT bounce_code FROM email_deliveries WHERE campaign_id=? AND bounce_code IS NOT NULL "
        "GROUP BY bounce_code ORDER BY COUNT(*) DESC LIMIT 1;",
        (identifier,),
    )
    top_bounce_code = top_bounce_rows[0]["bounce_code"] if top_bounce_rows else None
    recent_error = get_top_error(LOG_DIR)

    recommendation = "Monitor next campaign"
    if bounce_rate and bounce_rate > 5:
        recommendation = "Warm sending domain, retry failed jobs, monitor next campaign"
    if failed_jobs:
        recommendation += "; investigate failed batch jobs"

    return jsonify(
        {
            "type": "campaign",
            "identifier": identifier,
            "recipients": recipients,
            "bounce_rate": bounce_rate,
            "top_bounce_code": top_bounce_code,
            "recent_error": recent_error,
            "failed_batch_jobs": failed_jobs,
            "log_matches": log_matches,
            "recommendation": recommendation,
        }
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
