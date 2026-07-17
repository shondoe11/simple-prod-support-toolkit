# SQL Cheatsheet

Notes collected while writing the troubleshooting queries in `sql/`.

## Aggregation Patterns

- **Conditional counts with `SUM(CASE WHEN ...)`** — used repeatedly (`campaign_summary.sql`, `failed_jobs.sql`) to count rows matching a status without needing multiple queries or subqueries:

  ```sql
  SUM(CASE WHEN status = 'bounced' THEN 1 ELSE 0 END) AS bounced_count
  ```

- **Percentage of total** — combine a conditional `SUM`/`COUNT` with `ROUND(100.0 * x / y, 1)`. Use `100.0` (not `100`) to force floating point division in SQLite, otherwise integer division truncates to `0`.

- **Percentage of a correlated subquery total** (`bounce_analysis.sql`) — when the "total" isn't in the same GROUP BY, use a scalar subquery:

  ```sql
  ROUND(100.0 * COUNT(ed.delivery_id) / (SELECT COUNT(*) FROM email_deliveries WHERE status = 'bounced'), 1)
  ```

## Finding Duplicates

- `GROUP BY` + `HAVING COUNT(*) > 1` is the standard duplicate-detection pattern (`duplicate_customers.sql`).
- `LOWER(email)` before grouping catches case-variant duplicates that a naive `GROUP BY email` would miss.
- `GROUP_CONCAT(id)` returns the offending row IDs as a single comma-separated string, useful for a quick manual follow-up query.

## LEFT JOIN for "missing activity"

- `inactive_customers.sql` uses `LEFT JOIN` (not `INNER JOIN`) so customers with **zero** deliveries are still included, with `last_delivery` coming back `NULL`.
- Combine with `HAVING` (not `WHERE`) when the filter condition depends on an aggregate (`MAX(ed.delivered_at)`), since `WHERE` runs before aggregation and can't reference aggregate results.

## Relative Date Filtering

- SQLite date functions: `date('now', '-30 days')` for relative date comparisons — no need for a separate date library.

## "Slow" / Outlier Detection Without a Baseline Table

- `slow_queries.sql` flags outliers by comparing each row against a dynamically computed baseline rather than a hardcoded threshold:

  ```sql
  WHERE duration > (SELECT AVG(duration) * 1.5 FROM batch_jobs)
  ```

  This adapts automatically as the dataset's average duration changes, avoiding a magic-number threshold that would go stale.

## General

- Always `DROP TABLE IF EXISTS` in dependency order (children before parents) in `schema.sql` to avoid FK constraint errors on re-run.
- `PRAGMA foreign_keys = ON;` must be set explicitly in SQLite — foreign key enforcement is off by default.
