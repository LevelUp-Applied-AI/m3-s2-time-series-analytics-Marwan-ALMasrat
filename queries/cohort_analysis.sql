-- Identify each customer's first purchase date and assign cohort month
WITH first_purchase AS (
  SELECT
    customer_id,
    MIN(order_date) AS first_order_date,
    DATE_TRUNC('month', MIN(order_date)) AS cohort_month
  FROM orders
  WHERE status != 'cancelled'
  GROUP BY customer_id
),

-- Use ROW_NUMBER to rank customers within each cohort
cohort_numbered AS (
  SELECT
    customer_id,
    first_order_date,
    cohort_month,
    ROW_NUMBER() OVER (PARTITION BY cohort_month ORDER BY first_order_date) AS rn
  FROM first_purchase
),

-- Count total customers per cohort
cohort_size AS (
  SELECT cohort_month, COUNT(*) AS total_customers
  FROM first_purchase
  GROUP BY cohort_month
),

-- Find the next purchase date for each customer after their first order
repeat_purchases AS (
  SELECT
    fp.customer_id,
    fp.cohort_month,
    MIN(o.order_date) AS next_order_date
  FROM first_purchase fp
  JOIN orders o ON fp.customer_id = o.customer_id
    AND o.order_date > fp.first_order_date
    AND o.status != 'cancelled'
  GROUP BY fp.customer_id, fp.cohort_month
)

-- Final output: cohort size and retention rates at 30 / 60 / 90 days
SELECT
  cs.cohort_month,
  cs.total_customers,
  COUNT(CASE WHEN rp.next_order_date <= fp.first_order_date + 30 THEN 1 END) AS retained_30d,
  COUNT(CASE WHEN rp.next_order_date <= fp.first_order_date + 60 THEN 1 END) AS retained_60d,
  COUNT(CASE WHEN rp.next_order_date <= fp.first_order_date + 90 THEN 1 END) AS retained_90d,
  ROUND(100.0 * COUNT(CASE WHEN rp.next_order_date <= fp.first_order_date + 30 THEN 1 END) / cs.total_customers, 1) AS pct_30d,
  ROUND(100.0 * COUNT(CASE WHEN rp.next_order_date <= fp.first_order_date + 60 THEN 1 END) / cs.total_customers, 1) AS pct_60d,
  ROUND(100.0 * COUNT(CASE WHEN rp.next_order_date <= fp.first_order_date + 90 THEN 1 END) / cs.total_customers, 1) AS pct_90d
FROM cohort_size cs
JOIN first_purchase fp USING (cohort_month)
LEFT JOIN repeat_purchases rp ON fp.customer_id = rp.customer_id
GROUP BY cs.cohort_month, cs.total_customers
ORDER BY cs.cohort_month;