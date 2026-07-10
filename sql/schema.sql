-- production.db schema: customers, campaigns, email_deliveries, bounce_events, batch_jobs, audit_logs

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS audit_logs;
DROP TABLE IF EXISTS email_deliveries;
DROP TABLE IF EXISTS bounce_events;
DROP TABLE IF EXISTS batch_jobs;
DROP TABLE IF EXISTS campaigns;
DROP TABLE IF EXISTS customers;

-- customers signed up to receive campaigns
CREATE TABLE customers (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    email       TEXT NOT NULL UNIQUE,
    first_name  TEXT NOT NULL,
    last_name   TEXT NOT NULL,
    status      TEXT NOT NULL CHECK (status IN ('active', 'inactive', 'unsubscribed')),
    created_at  TEXT NOT NULL DEFAULT (datetime('now'))
);

-- campaigns sent to customers
CREATE TABLE campaigns (
    campaign_id     TEXT PRIMARY KEY,
    campaign_name   TEXT NOT NULL,
    sending_domain  TEXT NOT NULL,
    send_time       TEXT NOT NULL
);

-- ref table for smtp bounce codes
CREATE TABLE bounce_events (
    bounce_code    TEXT PRIMARY KEY,
    description    TEXT NOT NULL,
    smtp_provider  TEXT NOT NULL,
    created_at     TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 1 row/email sent to customer as part of a campaign
CREATE TABLE email_deliveries (
    delivery_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    campaign_id   TEXT NOT NULL REFERENCES campaigns(campaign_id),
    customer_id   INTEGER NOT NULL REFERENCES customers(id),
    status        TEXT NOT NULL CHECK (status IN ('delivered', 'opened', 'clicked', 'bounced')),
    bounce_code   TEXT REFERENCES bounce_events(bounce_code),
    delivered_at  TEXT NOT NULL
);

-- scheduled/batch job run history
CREATE TABLE batch_jobs (
    job_name     TEXT NOT NULL,
    status       TEXT NOT NULL CHECK (status IN ('success', 'failed', 'running')),
    duration     INTEGER NOT NULL,
    retry_count  INTEGER NOT NULL DEFAULT 0,
    last_run     TEXT NOT NULL
);

-- audit trail (admin/system actions)
CREATE TABLE audit_logs (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    action     TEXT NOT NULL,
    user       TEXT NOT NULL,
    timestamp  TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_deliveries_campaign_id ON email_deliveries(campaign_id);
CREATE INDEX idx_deliveries_customer_id ON email_deliveries(customer_id);
CREATE INDEX idx_deliveries_bounce_code ON email_deliveries(bounce_code);
CREATE INDEX idx_batch_jobs_job_name ON batch_jobs(job_name);
