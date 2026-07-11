-- finds cust email dupes
SELECT
    LOWER(email) AS normalized_email,
    COUNT(*) AS occurrences,
    GROUP_CONCAT(id) AS customer_ids
FROM customers
GROUP BY LOWER(email)
HAVING COUNT(*) > 1;
