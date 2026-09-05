-- ============================================
-- E-Commerce SQL Analysis
-- ============================================


-- ============================================
-- Stage 1: Data Exploration
-- ============================================

-- Question 1
-- How many customers are in the database?
SELECT COUNT(customer_id)
FROM customers;

-- Question 2
-- How many orders are in the database?
SELECT COUNT(order_id)
FROM orders;

-- Question 3
-- How many products are in the database?
SELECT COUNT(product_id)
FROM products;

-- Question 4
-- How many product categories are in the database?
SELECT COUNT(category_id)
FROM categories;

-- Question 5
-- How many customers have never placed an order?
SELECT COUNT(customers.customer_id)
FROM customers
WHERE NOT EXISTS (
    SELECT 1
    FROM orders
    WHERE orders.customer_id = customers.customer_id
);

-- Question 6
-- What are the earliest and latest order dates?
-- Return both dates in one result.
SELECT
    MIN(order_date) AS earliest_order,
    MAX(order_date) AS latest_order
FROM orders;

-- Question 7
-- How many orders are there for each order status?
SELECT
    SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
    SUM(CASE WHEN status = 'Shipped' THEN 1 ELSE 0 END) AS shipped_orders,
    SUM(CASE WHEN status = 'Completed' THEN 1 ELSE 0 END) AS completed_orders
FROM orders;

SELECT
    status,
    COUNT(order_id) AS order_count
FROM orders
GROUP BY status;

-- Question 8
-- What is the total revenue generated from non-cancelled orders?
-- Revenue = quantity * unit_price
-- Non-cancelled orders have a status other than 'Cancelled'.
SELECT SUM(quantity * unit_price) AS total_revenue
FROM order_items
INNER JOIN orders ON order_items.order_id = orders.order_id
WHERE status <> 'Cancelled';
