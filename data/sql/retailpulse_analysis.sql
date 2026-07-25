CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    gender VARCHAR(20),
    age INT,
    city VARCHAR(100),
    join_date DATE,
    membership VARCHAR(20),
    annual_income_pkr NUMERIC(12,2)
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(150),
    category VARCHAR(100),
    brand VARCHAR(100),
    cost_price NUMERIC(10,2),
    selling_price NUMERIC(10,2)
);

CREATE TABLE stores (
    store_id INT PRIMARY KEY,
    store_name VARCHAR(150),
    city VARCHAR(100),
    store_size VARCHAR(20),
    opening_date DATE
);

CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    employee_name VARCHAR(100),
    position VARCHAR(100),
    store_id INT,
    hire_date DATE
);

CREATE TABLE suppliers (
    supplier_id INT PRIMARY KEY,
    supplier_name VARCHAR(150),
    city VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(50)
);

CREATE TABLE inventory (
    inventory_id INT PRIMARY KEY,
    store_id INT,
    product_id INT,
    stock_on_hand INT,
    reorder_level INT
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    store_id INT,
    employee_id INT,
    order_date DATE,
    payment_method VARCHAR(50)
);

CREATE TABLE order_details (
    order_detail_id INT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    unit_price NUMERIC(10,2),
    discount_percent NUMERIC(5,2)
);

ALTER TABLE employees
ADD CONSTRAINT fk_employee_store
FOREIGN KEY (store_id)
REFERENCES stores(store_id);

ALTER TABLE inventory
ADD CONSTRAINT fk_inventory_store
FOREIGN KEY (store_id)
REFERENCES stores(store_id);

ALTER TABLE inventory
ADD CONSTRAINT fk_inventory_product
FOREIGN KEY (product_id)
REFERENCES products(product_id);

ALTER TABLE orders
ADD CONSTRAINT fk_order_customer
FOREIGN KEY (customer_id)
REFERENCES customers(customer_id);

ALTER TABLE orders
ADD CONSTRAINT fk_order_store
FOREIGN KEY (store_id)
REFERENCES stores(store_id);

ALTER TABLE orders
ADD CONSTRAINT fk_order_employee
FOREIGN KEY (employee_id)
REFERENCES employees(employee_id);

ALTER TABLE order_details
ADD CONSTRAINT fk_detail_order
FOREIGN KEY (order_id)
REFERENCES orders(order_id);

ALTER TABLE order_details
ADD CONSTRAINT fk_detail_product
FOREIGN KEY (product_id)
REFERENCES products(product_id);



SELECT 
  (SELECT COUNT(*) FROM stores) AS stores_count,
  (SELECT COUNT(*) FROM products) AS products_count,
  (SELECT COUNT(*) FROM customers) AS customers_count;

  TRUNCATE TABLE public.stores CASCADE;

  INSERT INTO public.stores (store_id, store_name, city, store_size, opening_date)
VALUES (30, 'Store Branch 30', 'Karachi', 'Medium', '2022-01-01');


SELECT COUNT(*) FROM public.orders;


SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM order_details;


--1. Top 10 Customers by Revenue 

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.city,
    c.membership,
    ROUND(SUM(
        od.quantity * od.unit_price
        * (1 - od.discount_percent / 100)
    ), 2) AS total_revenue
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_details od
    ON o.order_id = od.order_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name,
    c.city,
    c.membership
ORDER BY total_revenue DESC
LIMIT 10;


--2. Best-Selling Products 

SELECT
    p.product_id,
    p.product_name,
    p.category,
    p.brand,
    SUM(od.quantity) AS total_units_sold,
    ROUND(SUM(
        od.quantity * od.unit_price
        * (1 - od.discount_percent / 100)
    ), 2) AS total_revenue
FROM products p
JOIN order_details od
    ON p.product_id = od.product_id
GROUP BY
    p.product_id,
    p.product_name,
    p.category,
    p.brand
ORDER BY total_units_sold DESC
LIMIT 10;


--3. Monthly Sales Trends

SELECT
    DATE_TRUNC('month', o.order_date)::DATE AS sales_month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(od.quantity) AS units_sold,
    ROUND(SUM(
        od.quantity * od.unit_price
        * (1 - od.discount_percent / 100)
    ), 2) AS total_revenue
FROM orders o
JOIN order_details od
    ON o.order_id = od.order_id
GROUP BY sales_month
ORDER BY sales_month;


--4. Revenue by City

SELECT
    s.city,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(
        od.quantity * od.unit_price
        * (1 - od.discount_percent / 100)
    ), 2) AS total_revenue
FROM stores s
JOIN orders o
    ON s.store_id = o.store_id
JOIN order_details od
    ON o.order_id = od.order_id
GROUP BY s.city
ORDER BY total_revenue DESC;

--5. Average Order Value (AOV)

SELECT
    ROUND(AVG(order_total), 2) AS average_order_value
FROM (
    SELECT
        o.order_id,
        SUM(
            od.quantity * od.unit_price
            * (1 - od.discount_percent / 100)
        ) AS order_total
    FROM orders o
    JOIN order_details od
        ON o.order_id = od.order_id
    GROUP BY o.order_id
) AS order_totals;

--6. Spending by Membership Level

SELECT
    c.membership,
    COUNT(DISTINCT c.customer_id) AS customers,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(
        od.quantity * od.unit_price
        * (1 - od.discount_percent / 100)
    ), 2) AS total_revenue,
    ROUND(AVG(
        od.quantity * od.unit_price
        * (1 - od.discount_percent / 100)
    ), 2) AS average_line_value
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_details od
    ON o.order_id = od.order_id
GROUP BY c.membership
ORDER BY total_revenue DESC;

--7. Store Performance

SELECT
    s.store_id,
    s.store_name,
    s.city,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(od.quantity) AS units_sold,
    ROUND(SUM(
        od.quantity * od.unit_price
        * (1 - od.discount_percent / 100)
    ), 2) AS total_revenue
FROM stores s
JOIN orders o
    ON s.store_id = o.store_id
JOIN order_details od
    ON o.order_id = od.order_id
GROUP BY
    s.store_id,
    s.store_name,
    s.city
ORDER BY total_revenue DESC;


--8. Employee Performance

SELECT
    e.employee_id,
    e.employee_name,
    e.position,
    s.store_name,
    COUNT(DISTINCT o.order_id) AS orders_handled,
    ROUND(SUM(
        od.quantity * od.unit_price
        * (1 - od.discount_percent / 100)
    ), 2) AS revenue_generated
FROM employees e
JOIN stores s
    ON e.store_id = s.store_id
JOIN orders o
    ON e.employee_id = o.employee_id
JOIN order_details od
    ON o.order_id = od.order_id
GROUP BY
    e.employee_id,
    e.employee_name,
    e.position,
    s.store_name
ORDER BY revenue_generated DESC;