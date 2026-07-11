-- find customers with no recent activity
SELECT
    c.id,
    c.email,
    c.first_name,
    c.last_name,
    c.status,
    MAX(ed.delivered_at) AS last_delivery
FROM customers c
LEFT JOIN email_deliveries ed ON ed.customer_id = c.id
GROUP BY c.id
HAVING c.status IN ('inactive', 'unsubscribed')
    OR last_delivery IS NULL
    OR last_delivery < date('now', '-30 days')
ORDER BY last_delivery ASC;
