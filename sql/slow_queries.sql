-- identify slow-running queries for troubleshooting
--& proxy: batch job runs that took significantly longer than the job's average duration
SELECT
    job_name,
    status,
    duration,
    last_run
FROM batch_jobs
WHERE duration > (SELECT AVG(duration) * 1.5 FROM batch_jobs)
ORDER BY duration DESC;
