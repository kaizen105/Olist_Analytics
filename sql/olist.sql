-- ============================================================
-- OLIST E-COMMERCE ANALYSIS 
-- ============================================================

-- ------------------------------------------------------------
-- PHASE 1: BASIC ANALYSIS
-- ------------------------------------------------------------

-- 1. Total orders, unique customers, total revenue, average order value
SELECT 
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS total_customers,
    SUM(p.payment_value) AS total_revenue,
    ROUND(AVG(p.payment_value), 2) AS avg_order_value
FROM orders o
JOIN payments p ON o.order_id = p.order_id;

-- 2. Revenue by state
SELECT 
    c.customer_state, 
    SUM(p.payment_value) AS total_revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN payments p ON o.order_id = p.order_id
GROUP BY c.customer_state
ORDER BY total_revenue DESC;

-- 3. Top 10 products by quantity sold
SELECT 
    product_id, 
    COUNT(order_item_id) AS quantity_sold
FROM order_items
GROUP BY product_id
ORDER BY quantity_sold DESC
LIMIT 10;

-- 4. Top 5 sellers by revenue
SELECT 
    seller_id, 
    SUM(price) AS total_revenue
FROM order_items
GROUP BY seller_id
ORDER BY total_revenue DESC
LIMIT 5;

-- 5. Order status distribution
SELECT 
    order_status, 
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;


-- ------------------------------------------------------------
-- PHASE 2: TIME SERIES & TRENDS
-- ------------------------------------------------------------

-- 6. Revenue by month
SELECT 
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month, 
    SUM(p.payment_value) AS total_revenue
FROM orders o
JOIN payments p ON o.order_id = p.order_id
GROUP BY month
ORDER BY month;

-- 7. Orders per month trend
SELECT 
    DATE_TRUNC('month', order_purchase_timestamp) AS month, 
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY month
ORDER BY month;

-- 8. Average delivery time in days
SELECT 
    ROUND(AVG(EXTRACT(DAY FROM (order_delivered_customer_date - order_purchase_timestamp))), 2) AS avg_delivery_days
FROM orders
WHERE order_status = 'delivered';

-- 9. On-time vs late deliveries
SELECT 
    CASE 
        WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'On-time'
        ELSE 'Late'
    END AS delivery_status,
    COUNT(order_id) AS total_orders,
    ROUND(COUNT(order_id)::numeric / SUM(COUNT(order_id)) OVER () * 100, 2) AS percentage
FROM orders
WHERE order_status = 'delivered'
GROUP BY delivery_status;

-- 10. Review scores distribution
SELECT 
    review_score, 
    COUNT(review_id) AS total_reviews
FROM reviews
GROUP BY review_score
ORDER BY review_score DESC;


-- ------------------------------------------------------------
-- PHASE 3: CUSTOMER BEHAVIOR
-- ------------------------------------------------------------

-- 11. Repeat customers (who bought more than once?)
SELECT 
    t1.customer_unique_id, 
    COUNT(t2.order_id) AS total_orders
FROM customers t1
JOIN orders t2 ON t1.customer_id = t2.customer_id
GROUP BY t1.customer_unique_id
HAVING COUNT(t2.order_id) > 1
ORDER BY total_orders DESC;

-- 12. Customer lifetime value (total spent per customer)
SELECT 
    t1.customer_unique_id, 
    SUM(t3.price) AS total_spend
FROM customers t1
JOIN orders t2 ON t1.customer_id = t2.customer_id
JOIN order_items t3 ON t2.order_id = t3.order_id
GROUP BY t1.customer_unique_id
ORDER BY total_spend DESC
LIMIT 10;

-- 13. Average orders per customer by state
SELECT 
    t1.customer_state,
    COUNT(t2.order_id)::numeric / COUNT(DISTINCT t1.customer_unique_id) AS average_orders
FROM customers t1
JOIN orders t2 ON t1.customer_id = t2.customer_id
GROUP BY t1.customer_state
ORDER BY average_orders DESC
LIMIT 10;

-- 14. Payment method breakdown
SELECT 
    payment_type, 
    COUNT(order_id) AS total_orders, 
    SUM(payment_value) AS total_amount
FROM payments
GROUP BY payment_type
ORDER BY total_orders DESC;


-- ------------------------------------------------------------
-- PHASE 4: PRODUCT & CATEGORY
-- ------------------------------------------------------------

-- 15. Category-wise revenue ranking
SELECT 
    t1.product_category_name, 
    SUM(t2.price) AS total_revenue
FROM products t1
JOIN order_items t2 ON t1.product_id = t2.product_id
GROUP BY t1.product_category_name
ORDER BY total_revenue DESC
LIMIT 10;

-- 16. Products with worst reviews (min 5 reviews to avoid noise)
SELECT 
    t1.product_id, 
    ROUND(AVG(t2.review_score), 2) AS avg_score,
    COUNT(t1.order_id) AS total_orders
FROM order_items t1
JOIN reviews t2 ON t1.order_id = t2.order_id
GROUP BY t1.product_id
HAVING AVG(t2.review_score) < 2 AND COUNT(t1.order_id) >= 5
ORDER BY avg_score ASC
LIMIT 10;

-- 17. Category with highest review score
SELECT 
    t1.product_category_name, 
    ROUND(AVG(t3.review_score), 2) AS avg_score
FROM products t1
JOIN order_items t2 ON t1.product_id = t2.product_id
JOIN reviews t3 ON t2.order_id = t3.order_id
GROUP BY t1.product_category_name
ORDER BY avg_score DESC
LIMIT 10;

-- 18. Most reviewed products
SELECT 
    t1.product_id,
    t1.product_category_name,
    COUNT(t3.review_id) AS total_reviews
FROM products t1
JOIN order_items t2 ON t1.product_id = t2.product_id
JOIN reviews t3 ON t2.order_id = t3.order_id
GROUP BY t1.product_id, t1.product_category_name
ORDER BY total_reviews DESC
LIMIT 10;


-- ------------------------------------------------------------
-- PHASE 5: ADVANCED (CTEs & WINDOW FUNCTIONS)
-- ------------------------------------------------------------

-- 19. Top customer in each state by total spend
WITH customer_spend AS (
    SELECT 
        c.customer_state, 
        c.customer_unique_id, 
        SUM(p.payment_value) AS total_spend
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN payments p ON o.order_id = p.order_id
    GROUP BY c.customer_state, c.customer_unique_id
),
ranked_customers AS (
    SELECT 
        customer_state, 
        customer_unique_id, 
        total_spend,
        ROW_NUMBER() OVER(PARTITION BY customer_state ORDER BY total_spend DESC) AS rank
    FROM customer_spend
)
SELECT 
    customer_state, 
    customer_unique_id, 
    total_spend
FROM ranked_customers
WHERE rank = 1
ORDER BY total_spend DESC;

-- 20. Products that are always late delivery (100% late rate, minimum 5 orders)
WITH delivery_stats AS (
    SELECT 
        oi.product_id,
        COUNT(o.order_id) AS total_orders,
        SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END) AS late_orders
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered' 
      AND o.order_delivered_customer_date IS NOT NULL
    GROUP BY oi.product_id
)
SELECT 
    product_id,
    total_orders,
    late_orders
FROM delivery_stats
WHERE total_orders = late_orders 
  AND total_orders >= 5
ORDER BY total_orders DESC;


-- 21. Seller performance ranking (orders, revenue, review score combined)
SELECT 
    oi.seller_id,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    SUM(oi.price) AS total_revenue,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
LEFT JOIN reviews r ON o.order_id = r.order_id
GROUP BY oi.seller_id
HAVING COUNT(DISTINCT oi.order_id) > 10
ORDER BY total_revenue DESC, avg_review_score DESC;


-- 22. Customer segments by spending (High, Medium, Low value)
WITH customer_spending AS (
    SELECT 
        c.customer_unique_id,
        SUM(p.payment_value) AS total_spend
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN payments p ON o.order_id = p.order_id
    GROUP BY c.customer_unique_id
)
SELECT 
    customer_unique_id,
    total_spend,
    CASE 
        WHEN total_spend >= 1000 THEN 'High Value'
        WHEN total_spend >= 250 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS spending_segment
FROM customer_spending
ORDER BY total_spend DESC;


-- 23. Average order value by city (using Geolocation, Customers, and Orders)
WITH unique_geo AS (
    SELECT DISTINCT geolocation_zip_code_prefix, geolocation_city, geolocation_state
    FROM geolocation
)
SELECT 
    g.geolocation_city AS city,
    g.geolocation_state AS state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(AVG(p.payment_value), 2) AS avg_order_value
FROM unique_geo g
JOIN customers c ON g.geolocation_zip_code_prefix = c.customer_zip_code_prefix
JOIN orders o ON c.customer_id = o.customer_id
JOIN payments p ON o.order_id = p.order_id
GROUP BY g.geolocation_city, g.geolocation_state
HAVING COUNT(DISTINCT o.order_id) > 50
ORDER BY avg_order_value DESC;


-- 24. Full chain: For each product category, show total revenue, avg review score, top seller, and top state customer
WITH category_base AS (
    SELECT 
        p.product_category_name,
        SUM(oi.price) AS total_revenue,
        ROUND(AVG(r.review_score), 2) AS avg_review_score
    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    JOIN orders o ON oi.order_id = o.order_id
    LEFT JOIN reviews r ON o.order_id = r.order_id
    GROUP BY p.product_category_name
),
seller_ranks AS (
    SELECT 
        p.product_category_name,
        oi.seller_id,
        SUM(oi.price) AS seller_revenue,
        ROW_NUMBER() OVER(PARTITION BY p.product_category_name ORDER BY SUM(oi.price) DESC) AS rnk
    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    GROUP BY p.product_category_name, oi.seller_id
),
state_ranks AS (
    SELECT 
        p.product_category_name,
        c.customer_state,
        COUNT(DISTINCT o.order_id) AS total_orders,
        ROW_NUMBER() OVER(PARTITION BY p.product_category_name ORDER BY COUNT(DISTINCT o.order_id) DESC) AS rnk
    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    JOIN orders o ON oi.order_id = o.order_id
    JOIN customers c ON o.customer_id = c.customer_id
    GROUP BY p.product_category_name, c.customer_state
)
SELECT 
    cb.product_category_name,
    cb.total_revenue,
    cb.avg_review_score,
    sr.seller_id AS top_seller,
    str.customer_state AS top_state
FROM category_base cb
LEFT JOIN seller_ranks sr 
    ON cb.product_category_name = sr.product_category_name AND sr.rnk = 1
LEFT JOIN state_ranks str 
    ON cb.product_category_name = str.product_category_name AND str.rnk = 1
WHERE cb.product_category_name IS NOT NULL
ORDER BY cb.total_revenue DESC;
