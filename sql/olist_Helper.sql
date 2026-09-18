CREATE OR REPLACE VIEW vw_fact_orders AS
WITH ItemAgg AS (
    SELECT 
        order_id, 
        SUM(price) AS total_items_price, 
        SUM(freight_value) AS total_freight
    FROM order_items
    GROUP BY order_id
),
PaymentAgg AS (
    SELECT 
        order_id, 
        SUM(payment_value) AS total_payment
    FROM payments -- Corrected table name here
    GROUP BY order_id
)
SELECT 
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    COALESCE(i.total_items_price, 0) AS total_items_price,
    COALESCE(i.total_freight, 0) AS total_freight,
    COALESCE(p.total_payment, 0) AS total_payment
FROM orders o
LEFT JOIN ItemAgg i ON o.order_id = i.order_id
LEFT JOIN PaymentAgg p ON o.order_id = p.order_id;

CREATE OR REPLACE VIEW vw_logistics_health AS
SELECT 
    order_id,
    order_status,
    order_purchase_timestamp,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    EXTRACT(DAY FROM (order_delivered_customer_date - order_purchase_timestamp)) AS delivery_time_days,
    CASE 
        WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 'Late'
        WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'On-Time'
        ELSE 'Pending/Unknown'
    END AS delivery_status
FROM orders
WHERE order_status = 'delivered';


CREATE OR REPLACE VIEW vw_customer_analytics AS
SELECT 
    c.customer_unique_id,
    COUNT(o.order_id) AS total_orders,
    MIN(o.order_purchase_timestamp) AS first_purchase_date,
    MAX(o.order_purchase_timestamp) AS last_purchase_date
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status != 'canceled'
GROUP BY c.customer_unique_id;