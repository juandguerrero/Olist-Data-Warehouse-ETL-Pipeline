USE OlistWh;

-- 1. Row Count Validation

-- Compare source and target row counts.

-- Example: Products

-- Source

SELECT COUNT(*)
FROM Olist.dbo.products;

-- Target

SELECT COUNT(*)
FROM DimProduct;

-- Sellers

-- Source

SELECT COUNT(*)
FROM Olist.dbo.sellers;

-- Target

SELECT COUNT(*)
FROM DimSeller;

-- Customers

-- Source

SELECT COUNT(*)
FROM Olist.dbo.customers;

-- Target

SELECT COUNT(*)
FROM DimCustomer;


-- 2. Revenue Reconciliation

-- One of the most important validations.

-- The total revenue in the warehouse should match the total revenue in the source.

-- Source Revenue

SELECT
    SUM(price) AS source_revenue
FROM  Olist.dbo.Order_items oi
JOIN  Olist.dbo.Orders o
    ON oi.order_id = o.order_id
WHERE o.order_status ='delivered';

--Warehouse Revenue

SELECT
    SUM(price) AS warehouse_revenue
FROM FactSales;

-- 3. Order Count Validation

-- Source

SELECT COUNT(*)
FROM  Olist.dbo.Order_items oi
JOIN  Olist.dbo.Orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered';

-- Warehouse
SELECT COUNT(*)
FROM FactSales;

-- The counts should match because FactSales is loaded from delivered order items.

-- 4. Duplicate Checks

-- Dimensions should not contain duplicate business keys.

-- Products

SELECT
    product_id,
    COUNT(*)
FROM DimProduct
GROUP BY product_id
HAVING COUNT(*) > 1;

-- Sellers

SELECT
    seller_id,
    COUNT(*)
FROM DimSeller
GROUP BY seller_id
HAVING COUNT(*) > 1;

-- Customers

SELECT
    customer_id,
    COUNT(*)
FROM DimCustomer
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- 5. Referential Integrity Checks

-- Make sure every foreign key points to a valid dimension record.

-- Products

SELECT COUNT(*)
FROM FactSales f
LEFT JOIN DimProduct p
    ON f.product_key = p.product_key
WHERE p.product_key IS NULL;

-- Sellers

SELECT COUNT(*)
FROM FactSales f
LEFT JOIN DimSeller s
    ON f.seller_key = s.seller_key
WHERE s.seller_key IS NULL;

-- 6. Delivery Time Validation

-- Verify that the transformation was calculated correctly.

-- Source

SELECT
    AVG(
        DATEDIFF(
            DAY,
            order_purchase_timestamp,
            order_delivered_customer_date
        )
    )
FROM Olist.dbo.Orders
WHERE order_status = 'delivered';

--Warehouse

SELECT AVG(delivery_days)
FROM FactSales;

-- The values should be very close or identical.


-- 7. Late Delivery Validation

-- Source

SELECT COUNT(*)
FROM Olist.dbo.Orders
WHERE order_delivered_customer_date >
      order_estimated_delivery_date;

-- Warehouse

SELECT COUNT(DISTINCT order_id)
FROM FactSales
WHERE late_delivery_flag = 1;


-- What this does --
-- The first query returns all late orders from the source.
-- The second query returns all late orders from the warehouse.
-- EXCEPT shows any late order that exists in the source but not in the warehouse.

SELECT o.order_id
FROM Olist.dbo.orders o
WHERE o.order_delivered_customer_date >
      o.order_estimated_delivery_date

EXCEPT

SELECT DISTINCT order_id
FROM FactSales
WHERE late_delivery_flag = 1;

-- You found the missing order:
-- 1950d777989f6a877539f53795b4c3c3
-- Now investigate it with these queries:

SELECT *
FROM Olist.dbo.orders
WHERE order_id = '1950d777989f6a877539f53795b4c3c3';

SELECT *
FROM Olist.dbo.order_items
WHERE order_id = '1950d777989f6a877539f53795b4c3c3';

/*
=========================================
8. ETL VALIDATION REPORT
=========================================

Validation Summary

✓ Row Count Validation
- Products: 32,951 → 32,951
- Sellers: 3,095 → 3,095
- Customers: 99,441 → 99,441

✓ Revenue Reconciliation
- Source:    13,221,498.1120569
- Warehouse: 13,221,498.11
- Difference due to DECIMAL(10,2) rounding.

✓ Order Count Validation
- Source:    110,197
- Warehouse: 110,197

✓ Duplicate Checks
- DimProduct: 0 duplicates
- DimSeller: 0 duplicates
- DimCustomer: 0 duplicates

✓ Referential Integrity
- FactSales → DimProduct: 0 invalid records
- FactSales → DimSeller: 0 invalid records

✓ Delivery Time Validation
- Average delivery time matches (12 days).

✓ Late Delivery Validation
- Source: 7,827
- Warehouse: 7,826

The missing order (1950d777989f6a877539f53795b4c3c3)
has status = 'canceled'. Since the ETL loads only
delivered orders, this difference is expected.

Overall Result: ETL validation PASSED.
*/