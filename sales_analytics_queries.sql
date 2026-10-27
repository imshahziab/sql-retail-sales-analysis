-- ====================================================================
-- Retail Sales & Business Intelligence Analytics
-- Author: Muhammad Shahziab Javed
-- Description: Advanced queries for sales trends, customer value, and inventory
-- ====================================================================

-- 1. Monthly Revenue & MoM (Month-over-Month) Growth
WITH MonthlySales AS (
    SELECT 
        STRFTIME('%Y-%m', order_date) AS sales_month,
        ROUND(SUM(total_amount), 2) AS total_revenue,
        COUNT(DISTINCT order_id) AS total_orders
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY sales_month
)
SELECT 
    sales_month,
    total_revenue,
    total_orders,
    ROUND(
        (total_revenue - LAG(total_revenue, 1) OVER (ORDER BY sales_month)) 
        / LAG(total_revenue, 1) OVER (ORDER BY sales_month) * 100, 2
    ) AS mom_growth_percentage
FROM MonthlySales;

-- 2. Top 10 High-Value Customers (Customer Lifetime Value Baseline)
SELECT 
    c.customer_id,
    c.customer_name,
    COUNT(o.order_id) AS total_purchases,
    ROUND(SUM(o.total_amount), 2) AS lifetime_spent,
    ROUND(AVG(o.total_amount), 2) AS average_order_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status = 'Completed'
GROUP BY c.customer_id, c.customer_name
ORDER BY lifetime_spent DESC
LIMIT 10;

-- 3. Product Category Profitability & Margin Contribution
SELECT 
    p.category_name,
    COUNT(oi.order_item_id) AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS gross_sales,
    ROUND(SUM(oi.quantity * (oi.unit_price - p.cost_price)), 2) AS total_profit,
    ROUND(
        (SUM(oi.quantity * (oi.unit_price - p.cost_price)) / SUM(oi.quantity * oi.unit_price)) * 100, 2
    ) AS profit_margin_pct
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.category_name
ORDER BY total_profit DESC;

-- 4. Customer Retention: Identifying Repeat Buyers vs One-Time Buyers
WITH CustomerPurchaseCounts AS (
    SELECT 
        customer_id,
        COUNT(order_id) AS order_count
    FROM orders
    GROUP BY customer_id
)
SELECT 
    CASE 
        WHEN order_count = 1 THEN 'One-time Customer'
        WHEN order_count BETWEEN 2 AND 4 THEN 'Repeat Customer'
        ELSE 'Loyal Customer (5+ orders)'
    END AS customer_segment,
    COUNT(customer_id) AS customer_count,
    ROUND(COUNT(customer_id) * 100.0 / (SELECT COUNT(*) FROM CustomerPurchaseCounts), 2) AS percentage_share
FROM CustomerPurchaseCounts
GROUP BY customer_segment;
