-- Aggregate daily revenue and order count
WITH daily_revenue AS (
  SELECT
    o.order_date::date                AS day,
    SUM(oi.quantity * oi.unit_price)  AS revenue,
    COUNT(DISTINCT o.order_id)        AS order_count
  FROM orders o
  JOIN order_items oi ON o.order_id = oi.order_id
  WHERE o.status != 'cancelled'
  GROUP BY 1
)
SELECT
  day,
  revenue,
  order_count,
  -- 7-day moving average of daily revenue (current row + 6 preceding)
  ROUND(AVG(revenue) OVER (
    ORDER BY day
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ), 2) AS revenue_7day_ma,
  -- 30-day moving average of daily revenue (current row + 29 preceding)
  ROUND(AVG(revenue) OVER (
    ORDER BY day
    ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
  ), 2) AS revenue_30day_ma,
  -- 7-day moving average of daily order count
  ROUND(AVG(order_count) OVER (
    ORDER BY day
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ), 1) AS orders_7day_ma
FROM daily_revenue
ORDER BY day;