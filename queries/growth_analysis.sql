-- Monthly revenue and order volume with month-over-month growth rates
WITH monthly_revenue AS (
  SELECT
    DATE_TRUNC('month', o.order_date) AS month,
    SUM(oi.quantity * oi.unit_price)  AS revenue,
    COUNT(DISTINCT o.order_id)        AS order_count
  FROM orders o
  JOIN order_items oi ON o.order_id = oi.order_id
  WHERE o.status != 'cancelled'
  GROUP BY 1
)
SELECT
  month,
  revenue,
  order_count,
  LAG(revenue)      OVER (ORDER BY month) AS prev_month_revenue,
  LAG(order_count)  OVER (ORDER BY month) AS prev_month_orders,
  -- Month-over-month revenue growth rate
  ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
        / NULLIF(LAG(revenue) OVER (ORDER BY month), 0), 1) AS mom_revenue_growth,
  -- Month-over-month order volume growth rate
  ROUND(100.0 * (order_count - LAG(order_count) OVER (ORDER BY month))
        / NULLIF(LAG(order_count) OVER (ORDER BY month), 0), 1) AS mom_order_growth
FROM monthly_revenue
ORDER BY month;

-- Quarter-over-quarter revenue growth
WITH quarterly_revenue AS (
  SELECT
    DATE_TRUNC('quarter', o.order_date) AS quarter,
    SUM(oi.quantity * oi.unit_price)    AS revenue
  FROM orders o
  JOIN order_items oi ON o.order_id = oi.order_id
  WHERE o.status != 'cancelled'
  GROUP BY 1
)
SELECT
  quarter,
  revenue,
  LAG(revenue) OVER (ORDER BY quarter) AS prev_quarter_revenue,
  -- Quarter-over-quarter revenue growth rate
  ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY quarter))
        / NULLIF(LAG(revenue) OVER (ORDER BY quarter), 0), 1) AS qoq_growth
FROM quarterly_revenue
ORDER BY quarter;