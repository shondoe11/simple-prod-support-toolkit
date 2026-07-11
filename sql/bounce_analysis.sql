-- analyzes bounce codes + rates across campaigns
SELECT
    be.bounce_code,
    be.description,
    be.smtp_provider,
    COUNT(ed.delivery_id) AS bounce_count,
    ROUND(100.0 * COUNT(ed.delivery_id) / (SELECT COUNT(*) FROM email_deliveries WHERE status = 'bounced'), 1) AS pct_of_all_bounces
FROM bounce_events be
JOIN email_deliveries ed ON ed.bounce_code = be.bounce_code
GROUP BY be.bounce_code, be.description, be.smtp_provider
ORDER BY bounce_count DESC;
