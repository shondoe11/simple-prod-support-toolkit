-- campaign performance summary (recipients, bounce rate, delivery status breakdown)
SELECT
    c.campaign_id,
    c.campaign_name,
    COUNT(ed.delivery_id) AS total_recipients,
    SUM(CASE WHEN ed.status = 'delivered' THEN 1 ELSE 0 END) AS delivered_count,
    SUM(CASE WHEN ed.status = 'opened' THEN 1 ELSE 0 END) AS opened_count,
    SUM(CASE WHEN ed.status = 'clicked' THEN 1 ELSE 0 END) AS clicked_count,
    SUM(CASE WHEN ed.status = 'bounced' THEN 1 ELSE 0 END) AS bounced_count,
    ROUND(100.0 * SUM(CASE WHEN ed.status = 'bounced' THEN 1 ELSE 0 END) / COUNT(ed.delivery_id), 1) AS bounce_rate_pct
FROM campaigns c
JOIN email_deliveries ed ON ed.campaign_id = c.campaign_id
GROUP BY c.campaign_id, c.campaign_name
ORDER BY bounce_rate_pct DESC;
