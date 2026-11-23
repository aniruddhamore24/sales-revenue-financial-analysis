-- =====================================================================
-- SALES & REVENUE FINANCIAL ANALYSIS - SQL (SQLite / MySQL friendly)
-- Data: sales_data.csv (600 synthetic sales orders, 2025)
-- Import the CSV into a table named sales.
-- =====================================================================

CREATE TABLE sales (
    order_id       VARCHAR(10),
    order_date     DATE,
    month_no       INT,
    region         VARCHAR(20),
    category       VARCHAR(30),
    product        VARCHAR(30),
    customer_type  VARCHAR(20),
    qty            INT,
    unit_price     DECIMAL(10,2),
    unit_cost      DECIMAL(10,2),
    discount_pct   DECIMAL(4,2),
    revenue        DECIMAL(14,2),   -- qty * unit_price * (1 - discount)
    cogs           DECIMAL(14,2),   -- qty * unit_cost
    gross_profit   DECIMAL(14,2)    -- revenue - cogs
);

-- Q1. Overall KPIs
SELECT COUNT(*) AS orders,
       ROUND(SUM(revenue), 0)       AS total_revenue,
       ROUND(SUM(gross_profit), 0)  AS gross_profit,
       ROUND(100.0 * SUM(gross_profit) / SUM(revenue), 1) AS margin_pct,
       ROUND(AVG(revenue), 0)       AS avg_order_value
FROM sales;

-- Q2. Monthly revenue, profit and margin
SELECT month_no,
       COUNT(*) AS orders,
       ROUND(SUM(revenue), 0)      AS revenue,
       ROUND(SUM(gross_profit), 0) AS gross_profit,
       ROUND(100.0 * SUM(gross_profit) / SUM(revenue), 1) AS margin_pct
FROM sales
GROUP BY month_no
ORDER BY month_no;

-- Q3. Month-over-month growth (CTE + LAG window function)
WITH m AS (
    SELECT month_no, SUM(revenue) AS revenue
    FROM sales
    GROUP BY month_no
)
SELECT month_no,
       ROUND(revenue, 0) AS revenue,
       ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month_no))
             / LAG(revenue) OVER (ORDER BY month_no), 1) AS mom_growth_pct
FROM m
ORDER BY month_no;

-- Q4. Revenue and margin by region (with revenue share)
SELECT region,
       ROUND(SUM(revenue), 0) AS revenue,
       ROUND(100.0 * SUM(revenue) / (SELECT SUM(revenue) FROM sales), 1) AS revenue_share_pct,
       ROUND(100.0 * SUM(gross_profit) / SUM(revenue), 1) AS margin_pct
FROM sales
GROUP BY region
ORDER BY revenue DESC;

-- Q5. Category margin vs 33% target
SELECT category,
       ROUND(SUM(revenue), 0) AS revenue,
       ROUND(100.0 * SUM(gross_profit) / SUM(revenue), 1) AS margin_pct,
       CASE WHEN 100.0 * SUM(gross_profit) / SUM(revenue) >= 33
            THEN 'On target' ELSE 'Below target' END AS vs_target
FROM sales
GROUP BY category
ORDER BY margin_pct DESC;

-- Q6. Top 5 products by gross profit
SELECT product, category,
       ROUND(SUM(revenue), 0)      AS revenue,
       ROUND(SUM(gross_profit), 0) AS gross_profit
FROM sales
GROUP BY product, category
ORDER BY gross_profit DESC
LIMIT 5;

-- Q7. Best product within each category (RANK + PARTITION BY)
WITH p AS (
    SELECT category, product, SUM(revenue) AS revenue
    FROM sales
    GROUP BY category, product
),
r AS (
    SELECT *, RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS rnk
    FROM p
)
SELECT category, product, ROUND(revenue, 0) AS revenue
FROM r
WHERE rnk = 1;

-- Q8. Customer type analysis: revenue, average discount, margin
SELECT customer_type,
       COUNT(*) AS orders,
       ROUND(SUM(revenue), 0) AS revenue,
       ROUND(100 * AVG(discount_pct), 1) AS avg_discount_pct,
       ROUND(100.0 * SUM(gross_profit) / SUM(revenue), 1) AS margin_pct
FROM sales
GROUP BY customer_type
ORDER BY revenue DESC;

-- Q9. Running (cumulative) revenue by month
WITH m AS (
    SELECT month_no, SUM(revenue) AS revenue FROM sales GROUP BY month_no
)
SELECT month_no,
       ROUND(revenue, 0) AS revenue,
       ROUND(SUM(revenue) OVER (ORDER BY month_no), 0) AS cumulative_revenue
FROM m
ORDER BY month_no;
