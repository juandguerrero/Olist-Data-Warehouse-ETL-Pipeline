USE OlistWh;

-- 1. Load DimDate

-- Extract all purchase dates from orders.

INSERT INTO DimDate (
    date_key,
    full_date,
    day_number,
    month_number,
    month_name,
    quarter_number,
    year_number
)
SELECT DISTINCT
    CAST(FORMAT(order_purchase_timestamp, 'yyyyMMdd') AS INT) AS date_key,
    CAST(order_purchase_timestamp AS DATE) AS full_date,
    DAY(order_purchase_timestamp) AS day_number,
    MONTH(order_purchase_timestamp) AS month_number,
    DATENAME(MONTH, order_purchase_timestamp) AS month_name,
    DATEPART(QUARTER, order_purchase_timestamp) AS quarter_number,
    YEAR(order_purchase_timestamp) AS year_number
FROM Olist.dbo.Orders
WHERE order_purchase_timestamp IS NOT NULL
ORDER BY CAST(order_purchase_timestamp AS DATE) DESC;

-- Transformation performed --
-- Converts timestamp to a warehouse date key (YYYYMMDD)
-- Extracts day, month, quarter, and year

-- 2. Load DimProduct

-- Join to the translation table if you want English category names.

INSERT INTO DimProduct (
    product_id,
    category_name
)
SELECT DISTINCT
    p.product_id,
    t.product_category_name_english
FROM Olist.dbo.Products p
LEFT JOIN Olist.dbo.Product_category_name_translation t
    ON p.product_category_name = t.product_category_name;

-- Cleaning / Transformation --
-- Removes duplicates via DISTINCT
-- Translates category names to English
-- Preserves products with missing translations using LEFT JOIN

-- 3. Load DimSeller

INSERT INTO DimSeller (
    seller_id,
    seller_city,
    seller_state
)
SELECT DISTINCT
    seller_id,
    UPPER(LTRIM(RTRIM(seller_city))),
    seller_state
FROM Olist.dbo.Sellers;

-- Cleaning --
-- Remove duplicates
-- Standardize city names

-- 4. Load DimCustomer

-- Load DimCustomer

INSERT INTO DimCustomer (
    customer_id,
    customer_unique_id,
    customer_city,
    customer_state
)
SELECT DISTINCT
    customer_id,
    customer_unique_id,
    UPPER(LTRIM(RTRIM(customer_city))),
    customer_state
FROM Olist.dbo.Customers;

-- 5. Populate FactSales 

-- This is where most transformations occur.

-- Business Measures

-- You need:

-- Revenue
-- Freight cost
-- Delivery days
-- Late delivery flag

INSERT INTO FactSales (
    order_id,
    date_key,
    product_key,
    seller_key,
    customer_key,
    price,
    freight_value,
    delivery_days,
    late_delivery_flag
)
SELECT
    oi.order_id,

    CAST(FORMAT(o.order_purchase_timestamp, 'yyyyMMdd') AS INT),

    dp.product_key,
    ds.seller_key,
    dc.customer_key,

    oi.price,
    oi.freight_value,

    DATEDIFF(
        DAY,
        o.order_purchase_timestamp,
        o.order_delivered_customer_date
    ) AS delivery_days,

    CASE
        WHEN o.order_delivered_customer_date >
             o.order_estimated_delivery_date
        THEN 1
        ELSE 0
    END AS late_delivery_flag

FROM Olist.dbo.Order_items oi

INNER JOIN Olist.dbo.Orders o
    ON oi.order_id = o.order_id

INNER JOIN DimProduct dp
    ON oi.product_id = dp.product_id

INNER JOIN DimSeller ds
    ON oi.seller_id = ds.seller_id

INNER JOIN Olist.dbo.Customers c
    ON o.customer_id = c.customer_id

INNER JOIN DimCustomer dc
    ON c.customer_id = dc.customer_id

WHERE o.order_status = 'delivered';

