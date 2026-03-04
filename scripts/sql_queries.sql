use olist_ecommerce;

-- Qusetion - 1
SELECT 
    YEAR(order_purchase_timestamp) AS order_year,
    COUNT(order_id) AS total_orders
FROM olist_orders
GROUP BY YEAR(order_purchase_timestamp)
ORDER BY order_year;

-- Question - 2
SELECT 
    t.product_category_name_english AS category,
    round(SUM(oi.price), 2) AS total_revenue
FROM olist_order_items oi
JOIN olist_products p 
    ON oi.product_id = p.product_id
JOIN product_category_translation t 
    ON p.product_category_name = t.product_category_name
GROUP BY t.product_category_name_english
ORDER BY total_revenue DESC
LIMIT 5;

-- Question - 3
SELECT 
    customer_state AS state,
    COUNT(DISTINCT customer_id) AS total_customers
FROM olist_customers
GROUP BY customer_state
ORDER BY total_customers DESC;

-- Question - 4
SELECT 
    payment_type,
    COUNT(*) AS total_transactions
FROM olist_order_payments
GROUP BY payment_type
ORDER BY total_transactions DESC;

-- Question - 5
SELECT 
    c.customer_city AS city,
    COUNT(o.order_id) AS total_orders
FROM olist_orders o
JOIN olist_customers c
    ON o.customer_id = c.customer_id
GROUP BY c.customer_city
ORDER BY total_orders DESC
LIMIT 10;

-- Question - 6
SELECT 
    c.customer_state AS state,
    AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)) AS avg_delivery_days
FROM olist_orders o
JOIN olist_customers c
    ON o.customer_id = c.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delivery_days DESC;

-- Question - 7
SELECT 
    AVG(p.payment_installments) AS avg_installments
FROM (
    SELECT 
        oi.order_id,
        SUM(oi.price) AS total_order_value
    FROM olist_order_items oi
    GROUP BY oi.order_id
    HAVING total_order_value > 500
) high_value_orders
JOIN olist_order_payments p
    ON high_value_orders.order_id = p.order_id;

-- Question - 8
SELECT 
    oi.seller_id,
    AVG(r.review_score) AS avg_review_score,
    COUNT(DISTINCT oi.order_id) AS total_orders
FROM olist_order_items oi
JOIN olist_order_reviews r
    ON oi.order_id = r.order_id
GROUP BY oi.seller_id
HAVING total_orders >= 50
ORDER BY avg_review_score DESC
LIMIT 10;

-- Question - 9
SELECT 
    t.product_category_name_english AS category,
    SUM(oi.freight_value) / SUM(oi.price) AS shipping_ratio
FROM olist_order_items oi
JOIN olist_products p
    ON oi.product_id = p.product_id
JOIN product_category_translation t
    ON p.product_category_name = t.product_category_name
GROUP BY t.product_category_name_english
ORDER BY shipping_ratio DESC;

-- Question - 10
SELECT 
    customer_id,
    COUNT(order_id) AS total_orders
FROM olist_orders
GROUP BY customer_id;

SELECT 
    CASE 
        WHEN total_orders = 1 THEN 'One-time Buyer'
        WHEN total_orders > 2 THEN 'Repeat Buyer'
        ELSE 'Two-time Buyer'
    END AS customer_type,
    COUNT(*) AS total_customers
FROM (
    SELECT 
        customer_id,
        COUNT(order_id) AS total_orders
    FROM olist_orders
    GROUP BY customer_id
) customer_orders
GROUP BY customer_type;

-- Question - 11
SELECT 
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS order_month,
    COUNT(*) AS total_orders,
    SUM(
        CASE 
            WHEN order_delivered_customer_date > order_estimated_delivery_date 
            THEN 1 ELSE 0 
        END
    ) AS late_orders,
    (SUM(
        CASE 
            WHEN order_delivered_customer_date > order_estimated_delivery_date 
            THEN 1 ELSE 0 
        END
    ) / COUNT(*)) * 100 AS late_percentage
FROM olist_orders
WHERE order_delivered_customer_date IS NOT NULL
GROUP BY order_month
ORDER BY order_month;

-- Question - 12
SELECT 
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
    SUM(oi.price) AS total_revenue
FROM olist_orders o
JOIN olist_order_items oi
    ON o.order_id = oi.order_id
GROUP BY order_month
ORDER BY order_month;

-- Question - 13
SELECT 
    order_month,
    total_revenue,
    LAG(total_revenue) OVER (ORDER BY order_month) AS prev_month_revenue,
    ((total_revenue - LAG(total_revenue) OVER (ORDER BY order_month)) 
        / LAG(total_revenue) OVER (ORDER BY order_month)) * 100 AS mom_growth_percentage
FROM (
    SELECT 
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
        SUM(oi.price) AS total_revenue
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    GROUP BY order_month
) monthly_revenue
ORDER BY order_month;

-- Question - 14
SELECT 
    o.customer_id,
    DATEDIFF(
        (SELECT MAX(order_purchase_timestamp) FROM olist_orders),
        MAX(o.order_purchase_timestamp)
    ) AS recency,
    COUNT(DISTINCT o.order_id) AS frequency,
    SUM(oi.price) AS monetary
FROM olist_orders o
JOIN olist_order_items oi
    ON o.order_id = oi.order_id
GROUP BY o.customer_id;

-- Question - 15
SELECT 
    o.customer_id,
    SUM(oi.price) AS total_spent
FROM olist_orders o
JOIN olist_order_items oi
    ON o.order_id = oi.order_id
GROUP BY o.customer_id
ORDER BY total_spent DESC;

-- Question - 16
WITH monthly_category_revenue AS (
    SELECT 
        t.product_category_name_english AS category,
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
        SUM(oi.price) AS monthly_revenue
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_products p
        ON oi.product_id = p.product_id
    JOIN product_category_translation t
        ON p.product_category_name = t.product_category_name
    GROUP BY category, order_month
),

revenue_trend AS (
    SELECT 
        category,
        order_month,
        monthly_revenue,
        LAG(monthly_revenue, 1) OVER (PARTITION BY category ORDER BY order_month) AS prev1,
        LAG(monthly_revenue, 2) OVER (PARTITION BY category ORDER BY order_month) AS prev2,
        LAG(monthly_revenue, 3) OVER (PARTITION BY category ORDER BY order_month) AS prev3
    FROM monthly_category_revenue
)

SELECT DISTINCT category
FROM revenue_trend
WHERE 
    monthly_revenue < prev1
    AND prev1 < prev2
    AND prev2 < prev3;

-- Question - 17
SELECT 
    oi.seller_id,
    SUM(oi.price) AS total_revenue
FROM olist_order_items oi
GROUP BY oi.seller_id
ORDER BY total_revenue DESC;

-- Question - 18
SELECT 
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
    SUM(oi.price) AS total_revenue
FROM olist_orders o
JOIN olist_order_items oi
    ON o.order_id = oi.order_id
GROUP BY order_month
ORDER BY order_month;

-- Question - 19
SELECT 
    oi.order_id,
    SUM(oi.price) AS total_order_value,
    SUM(p.payment_value) AS total_payment_value,
    (SUM(p.payment_value) - SUM(oi.price)) AS difference
FROM olist_order_items oi
JOIN olist_order_payments p
    ON oi.order_id = p.order_id
GROUP BY oi.order_id
HAVING total_payment_value != total_order_value;

-- Question - 20
WITH seller_revenue AS (
    SELECT 
        oi.seller_id,
        SUM(oi.price) AS total_revenue,
        MAX(o.order_purchase_timestamp) AS last_sale_date
    FROM olist_order_items oi
    JOIN olist_orders o
        ON oi.order_id = o.order_id
    GROUP BY oi.seller_id
),

revenue_rank AS (
    SELECT 
        seller_id,
        total_revenue,
        last_sale_date,
        NTILE(4) OVER (ORDER BY total_revenue DESC) AS revenue_quartile
    FROM seller_revenue
)

SELECT 
    seller_id,
    total_revenue,
    last_sale_date
FROM revenue_rank
WHERE 
    revenue_quartile = 1   -- Top 25% sellers
    AND last_sale_date < DATE_SUB(
        (SELECT MAX(order_purchase_timestamp) FROM olist_orders),
        INTERVAL 90 DAY
    );
