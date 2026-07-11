-- lists failed batch jobs with retry counts
SELECT
    job_name,
    COUNT(*) AS total_runs,
    SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) AS failed_runs,
    ROUND(100.0 * SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) / COUNT(*), 1) AS failure_rate_pct,
    MAX(retry_count) AS max_retry_count,
    MAX(last_run) AS most_recent_run
FROM batch_jobs
GROUP BY job_name
ORDER BY failure_rate_pct DESC;
