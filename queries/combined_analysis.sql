-- Query 1: Monthly revenue by customer segment with growth rate and running total
WITH monthly_segment AS (
  SELECT
    DATE_TRUNC('month', o.order_date) AS month,
    c.segment,
    SUM(oi.quantity * oi.unit_price)  AS revenue
  FROM orders o
  JOIN order_items oi ON o.order_id = oi.order_id
  JOIN customers c ON o.customer_id = c.customer_id
  WHERE o.status != 'cancelled'
  GROUP BY 1, 2
)
SELECT
  month,
  segment,
  revenue,
  LAG(revenue) OVER (PARTITION BY segment ORDER BY month) AS prev_revenue,
  -- Month-over-month growth rate per segment
  ROUND(100.0 * (revenue - LAG(revenue) OVER (PARTITION BY segment ORDER BY month))
        / NULLIF(LAG(revenue) OVER (PARTITION BY segment ORDER BY month), 0), 1) AS growth_pct,
  -- Cumulative running total per segment
  SUM(revenue) OVER (
    PARTITION BY segment ORDER BY month
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_total
FROM monthly_segment
ORDER BY segment, month;


-- Query 2: Category revenue share per month with 3-month moving average
WITH category_monthly AS (
  SELECT
    DATE_TRUNC('month', o.order_date) AS month,
    p.category,
    SUM(oi.quantity * oi.unit_price)  AS revenue
  FROM orders o
  JOIN order_items oi ON o.order_id = oi.order_id
  JOIN products p ON oi.product_id = p.product_id
  WHERE o.status != 'cancelled'
  GROUP BY 1, 2
)
SELECT
  month,
  category,
  revenue,
  -- Category share of total monthly revenue
  ROUND(100.0 * revenue / SUM(revenue) OVER (PARTITION BY month), 1) AS share_pct,
  -- 3-month moving average of category revenue to smooth seasonal noise
  ROUND(AVG(revenue) OVER (
    PARTITION BY category ORDER BY month
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ), 2) AS revenue_3mo_ma
FROM category_monthly
ORDER BY month, category;