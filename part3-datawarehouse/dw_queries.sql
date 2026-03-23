-- ============================================================
-- Part 3.2 — Analytical Queries
-- Data Warehouse: retail_transactions star schema
-- ============================================================


-- ------------------------------------------------------------
-- Q1: Total sales revenue by product category for each month
-- ------------------------------------------------------------
-- Uses dim_date for month/year, dim_product for category,
-- and fact_sales for the pre-computed total_revenue measure.

SELECT
    d.year,
    d.month,
    d.month_name,
    p.category,
    SUM(f.total_revenue)                        AS total_revenue,
    SUM(f.units_sold)                           AS total_units
FROM
    fact_sales      f
    JOIN dim_date    d ON f.date_key    = d.date_key
    JOIN dim_product p ON f.product_key = p.product_key
GROUP BY
    d.year,
    d.month,
    d.month_name,
    p.category
ORDER BY
    d.year,
    d.month,
    p.category;


-- ------------------------------------------------------------
-- Q2: Top 2 performing stores by total revenue
-- ------------------------------------------------------------
-- Ranks all stores by their aggregate revenue and returns
-- only the top two.

SELECT
    s.store_name,
    s.store_city,
    SUM(f.total_revenue)    AS total_revenue,
    SUM(f.units_sold)       AS total_units_sold,
    COUNT(*)                AS transaction_count
FROM
    fact_sales  f
    JOIN dim_store s ON f.store_key = s.store_key
GROUP BY
    s.store_key,
    s.store_name,
    s.store_city
ORDER BY
    total_revenue DESC
LIMIT 2;


-- ------------------------------------------------------------
-- Q3: Month-over-month sales trend across all stores
-- ------------------------------------------------------------
-- Calculates each month's total revenue, the previous month's
-- revenue (using LAG), and the absolute and percentage change.

WITH monthly_revenue AS (
    SELECT
        d.year,
        d.month,
        d.month_name,
        SUM(f.total_revenue)    AS revenue
    FROM
        fact_sales  f
        JOIN dim_date d ON f.date_key = d.date_key
    GROUP BY
        d.year,
        d.month,
        d.month_name
),
mom AS (
    SELECT
        year,
        month,
        month_name,
        revenue,
        LAG(revenue) OVER (ORDER BY year, month)  AS prev_month_revenue
    FROM
        monthly_revenue
)
SELECT
    year,
    month,
    month_name,
    revenue                                                          AS current_revenue,
    prev_month_revenue,
    ROUND(revenue - prev_month_revenue, 2)                          AS revenue_change,
    CASE
        WHEN prev_month_revenue IS NULL OR prev_month_revenue = 0
            THEN NULL
        ELSE ROUND(
                 ((revenue - prev_month_revenue) / prev_month_revenue) * 100,
                 2)
    END                                                              AS pct_change
FROM
    mom
ORDER BY
    year,
    month;
