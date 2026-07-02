USE Olist;

-- Data Profiling

-- Customers

-- a)  Null values

SELECT
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS NullCustomerID,
    SUM(CASE WHEN customer_unique_id IS NULL THEN 1 ELSE 0 END) AS NullCustomerUniqueID,
    SUM(CASE WHEN customer_zip_code_prefix IS NULL THEN 1 ELSE 0 END) AS NullZipCodePrefix,
    SUM(CASE WHEN customer_city IS NULL THEN 1 ELSE 0 END) AS NullCity,
    SUM(CASE WHEN customer_state IS NULL THEN 1 ELSE 0 END) AS NullState
FROM dbo.Customers;

-- b) Duplicates

SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state,
    COUNT(*) AS DuplicateCount
FROM dbo.Customers
GROUP BY
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
HAVING COUNT(*) > 1;

-- c) Negative quantities

SELECT COUNT(*) AS NegativeZipCodes
FROM dbo.Customers
WHERE customer_zip_code_prefix < 0;

-- d) Inconsistent values

-- DISTINCT values

SELECT DISTINCT customer_city
FROM dbo.Customers
ORDER BY customer_city;

-- e) Normalize and compare (LOWER / UPPER)

SELECT
    LOWER(customer_city) AS normalized_city,
    COUNT(*) AS occurrences
FROM dbo.Customers
GROUP BY LOWER(customer_city)
ORDER BY occurrences DESC;

-- f) Detect leading/trailing spaces

SELECT *
FROM dbo.Customers
WHERE customer_city <> LTRIM(RTRIM(customer_city));

-- g) Look for hidden duplicates caused by formatting

SELECT
    customer_city,
    COUNT(*) AS count
FROM dbo.Customers
GROUP BY customer_city
HAVING COUNT(*) > 1
ORDER BY count DESC;

-- Then combine with normalization:

SELECT
    LOWER(LTRIM(RTRIM(customer_city))) AS clean_city,
    COUNT(*) AS count
FROM dbo.Customers
GROUP BY LOWER(LTRIM(RTRIM(customer_city)))
ORDER BY count DESC;

-- Check inconsistent categories

SELECT
    customer_state,
    COUNT(*) AS count
FROM dbo.Customers
GROUP BY customer_state
ORDER BY customer_state;

-- Order_items

-- a) Null values

SELECT
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS NullOrderID,
    SUM(CASE WHEN order_item_id IS NULL THEN 1 ELSE 0 END) AS NullOrderItemID,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS NullProductID,
    SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) AS NullSellerID,
    SUM(CASE WHEN shipping_limit_date IS NULL THEN 1 ELSE 0 END) AS NullShippingLimitDate,
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS NullPrice,
    SUM(CASE WHEN freight_value IS NULL THEN 1 ELSE 0 END) AS NullFreightValue
FROM dbo.Order_items;

-- b) Duplicate rows

SELECT
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value,
    COUNT(*) AS DuplicateCount
FROM dbo.Order_items
GROUP BY
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value
HAVING COUNT(*) > 1;

-- c) Negative values

SELECT COUNT(*) AS NegativePrices
FROM dbo.Order_items
WHERE price < 0;

SELECT COUNT(*) AS NegativeFreightValues
FROM dbo.Order_items
WHERE freight_value < 0;

-- d) Zero values (sometimes suspicious)

SELECT COUNT(*) AS ZeroPrices
FROM dbo.Order_items
WHERE price = 0;

SELECT COUNT(*) AS ZeroFreightValues
FROM dbo.Order_items
WHERE freight_value = 0;

-- e) Invalid dates

SELECT COUNT(*) AS FutureShippingDates
FROM dbo.Order_items
WHERE shipping_limit_date > GETDATE();

-- f) Product frequency

SELECT
    product_id,
    COUNT(*) AS occurrences
FROM dbo.Order_items
GROUP BY product_id
ORDER BY occurrences DESC;

-- g) Seller frequency

SELECT
    seller_id,
    COUNT(*) AS occurrences
FROM dbo.Order_items
GROUP BY seller_id
ORDER BY occurrences DESC;

-- h) Price statistics

SELECT
    MIN(price) AS MinPrice,
    MAX(price) AS MaxPrice,
    AVG(price) AS AvgPrice
FROM dbo.Order_items;

-- i) Freight statistics

SELECT
    MIN(freight_value) AS MinFreight,
    MAX(freight_value) AS MaxFreight,
    AVG(freight_value) AS AvgFreight
FROM dbo.Order_items;

-- j) Potential outliers (very expensive items)

SELECT *
FROM dbo.Order_items
WHERE price >
(
    SELECT AVG(price) + 3 * STDEV(price)
    FROM dbo.Order_items
)
ORDER BY price DESC;

-- k) Check duplicate order_item_id within the same order

SELECT
    order_id,
    order_item_id,
    COUNT(*) AS DuplicateCount
FROM dbo.Order_items
GROUP BY
    order_id,
    order_item_id
HAVING COUNT(*) > 1;

-- l) Orders associated with multiple sellers

SELECT
    order_id,
    COUNT(DISTINCT seller_id) AS SellerCount
FROM dbo.Order_items
GROUP BY order_id
HAVING COUNT(DISTINCT seller_id) > 1;

-- m) Orders associated with multiple products

SELECT
    order_id,
    COUNT(DISTINCT product_id) AS ProductCount
FROM dbo.Order_items
GROUP BY order_id
HAVING COUNT(DISTINCT product_id) > 1;

-- n) Order_items without a matching order
SELECT oi.*
FROM dbo.Order_items oi
LEFT JOIN dbo.Orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- o) Order_items without a matching product
SELECT oi.*
FROM dbo.Order_items oi
LEFT JOIN dbo.Products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- Orders

-- a) Null values

SELECT
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS NullOrderID,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS NullCustomerID,
    SUM(CASE WHEN order_status IS NULL THEN 1 ELSE 0 END) AS NullOrderStatus,
    SUM(CASE WHEN order_purchase_timestamp IS NULL THEN 1 ELSE 0 END) AS NullPurchaseTimestamp,
    SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END) AS NullApprovedAt,
    SUM(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END) AS NullDeliveredCarrierDate,
    SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS NullDeliveredCustomerDate,
    SUM(CASE WHEN order_estimated_delivery_date IS NULL THEN 1 ELSE 0 END) AS NullEstimatedDeliveryDate
FROM dbo.Orders;

-- b) Duplicate rows

SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    COUNT(*) AS DuplicateCount
FROM dbo.Orders
GROUP BY
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
HAVING COUNT(*) > 1;

-- c) Duplicate order IDs

SELECT
    order_id,
    COUNT(*) AS DuplicateCount
FROM dbo.Orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- d) Duplicate customer IDs

SELECT
    customer_id,
    COUNT(*) AS OrderCount
FROM dbo.Orders
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- e) Order status distribution

SELECT
    order_status,
    COUNT(*) AS Occurrences
FROM dbo.Orders
GROUP BY order_status
ORDER BY Occurrences DESC;

-- f) Invalid order status values

SELECT *
FROM dbo.Orders
WHERE order_status NOT IN
(
    'created',
    'approved',
    'invoiced',
    'processing',
    'shipped',
    'delivered',
    'canceled',
    'unavailable'
);

-- g) Leading/trailing spaces in order status

SELECT *
FROM dbo.Orders
WHERE order_status <> LTRIM(RTRIM(order_status));

-- h) Hidden duplicates in order status

SELECT
    LOWER(LTRIM(RTRIM(order_status))) AS CleanStatus,
    COUNT(*) AS Occurrences
FROM dbo.Orders
GROUP BY LOWER(LTRIM(RTRIM(order_status)))
ORDER BY Occurrences DESC;

-- i) Orders approved before purchase date

SELECT *
FROM dbo.Orders
WHERE order_approved_at IS NOT NULL
AND order_approved_at < order_purchase_timestamp;

-- j) Carrier received order before approval

SELECT *
FROM dbo.Orders
WHERE order_approved_at IS NOT NULL
AND order_delivered_carrier_date IS NOT NULL
AND order_delivered_carrier_date < order_approved_at;

-- k) Customer received order before carrier date

SELECT *
FROM dbo.Orders
WHERE order_delivered_carrier_date IS NOT NULL
AND order_delivered_customer_date IS NOT NULL
AND order_delivered_customer_date < order_delivered_carrier_date;

-- l) Estimated delivery before purchase date

SELECT *
FROM dbo.Orders
WHERE order_estimated_delivery_date < order_purchase_timestamp;

-- m) Delivery time statistics (days)

SELECT
    MIN(DATEDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date)) AS MinDays,
    MAX(DATEDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date)) AS MaxDays,
    AVG(CAST(DATEDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date) AS FLOAT)) AS AvgDays
FROM dbo.Orders
WHERE order_delivered_customer_date IS NOT NULL;

-- n) Approval time statistics (hours)

SELECT
    MIN(DATEDIFF(HOUR, order_purchase_timestamp, order_approved_at)) AS MinHours,
    MAX(DATEDIFF(HOUR, order_purchase_timestamp, order_approved_at)) AS MaxHours,
    AVG(CAST(DATEDIFF(HOUR, order_purchase_timestamp, order_approved_at) AS FLOAT)) AS AvgHours
FROM dbo.Orders
WHERE order_approved_at IS NOT NULL;

-- o) Late deliveries

SELECT *
FROM dbo.Orders
WHERE order_delivered_customer_date IS NOT NULL
AND order_delivered_customer_date > order_estimated_delivery_date;

-- p) Early deliveries

SELECT *
FROM dbo.Orders
WHERE order_delivered_customer_date IS NOT NULL
AND order_delivered_customer_date < order_estimated_delivery_date;

-- q) Potential outliers in delivery time

SELECT *
FROM dbo.Orders
WHERE DATEDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date) >
(
    SELECT
        AVG(CAST(DATEDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date) AS FLOAT))
        + 3 * STDEV(CAST(DATEDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date) AS FLOAT))
    FROM dbo.Orders
    WHERE order_delivered_customer_date IS NOT NULL
);

-- r) Delivery statistics summary

SELECT
    COUNT(*) AS TotalOrders,
    COUNT(order_delivered_customer_date) AS DeliveredOrders,
    MIN(DATEDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date)) AS MinDeliveryDays,
    MAX(DATEDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date)) AS MaxDeliveryDays,
    AVG(CAST(DATEDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date) AS FLOAT)) AS AvgDeliveryDays
FROM dbo.Orders
WHERE order_delivered_customer_date IS NOT NULL;

-- Product_category_name_translation

-- a) Null values

SELECT
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) AS NullProductCategoryName,
    SUM(CASE WHEN product_category_name_english IS NULL THEN 1 ELSE 0 END) AS NullProductCategoryNameEnglish
FROM dbo.Product_category_name_translation;

-- b) Duplicate rows

SELECT
    product_category_name,
    product_category_name_english,
    COUNT(*) AS DuplicateCount
FROM dbo.Product_category_name_translation
GROUP BY
    product_category_name,
    product_category_name_english
HAVING COUNT(*) > 1;

-- c) Duplicate Portuguese category names

SELECT
    product_category_name,
    COUNT(*) AS DuplicateCount
FROM dbo.Product_category_name_translation
GROUP BY product_category_name
HAVING COUNT(*) > 1;

-- d) Duplicate English category names

SELECT
    product_category_name_english,
    COUNT(*) AS DuplicateCount
FROM dbo.Product_category_name_translation
GROUP BY product_category_name_english
HAVING COUNT(*) > 1;

-- e) Distinct category counts

SELECT
    COUNT(DISTINCT product_category_name) AS DistinctPortugueseCategories,
    COUNT(DISTINCT product_category_name_english) AS DistinctEnglishCategories
FROM dbo.Product_category_name_translation;

-- f) Leading/trailing spaces in Portuguese names

SELECT *
FROM dbo.Product_category_name_translation
WHERE product_category_name <>
      LTRIM(RTRIM(product_category_name));

-- g) Leading/trailing spaces in English names

SELECT *
FROM dbo.Product_category_name_translation
WHERE product_category_name_english <>
      LTRIM(RTRIM(product_category_name_english));

-- h) Hidden duplicates in Portuguese names

SELECT
    LOWER(LTRIM(RTRIM(product_category_name))) AS CleanCategory,
    COUNT(*) AS Occurrences
FROM dbo.Product_category_name_translation
GROUP BY LOWER(LTRIM(RTRIM(product_category_name)))
HAVING COUNT(*) > 1
ORDER BY Occurrences DESC;

-- i) Hidden duplicates in English names

SELECT
    LOWER(LTRIM(RTRIM(product_category_name_english))) AS CleanCategory,
    COUNT(*) AS Occurrences
FROM dbo.Product_category_name_translation
GROUP BY LOWER(LTRIM(RTRIM(product_category_name_english)))
HAVING COUNT(*) > 1
ORDER BY Occurrences DESC;

-- j) Empty Portuguese names

SELECT *
FROM dbo.Product_category_name_translation
WHERE product_category_name = '';

-- k) Empty English names

SELECT *
FROM dbo.Product_category_name_translation
WHERE product_category_name_english = '';

-- l) Length statistics for Portuguese names

SELECT
    MIN(LEN(product_category_name)) AS MinLength,
    MAX(LEN(product_category_name)) AS MaxLength,
    AVG(CAST(LEN(product_category_name) AS FLOAT)) AS AvgLength
FROM dbo.Product_category_name_translation;

-- m) Length statistics for English names

SELECT
    MIN(LEN(product_category_name_english)) AS MinLength,
    MAX(LEN(product_category_name_english)) AS MaxLength,
    AVG(CAST(LEN(product_category_name_english) AS FLOAT)) AS AvgLength
FROM dbo.Product_category_name_translation;

-- n) Portuguese names with unusual lengths

SELECT *
FROM dbo.Product_category_name_translation
WHERE LEN(product_category_name) >
(
    SELECT
        AVG(CAST(LEN(product_category_name) AS FLOAT))
        + 3 * STDEV(CAST(LEN(product_category_name) AS FLOAT))
    FROM dbo.Product_category_name_translation
);

-- o) English names with unusual lengths

SELECT *
FROM dbo.Product_category_name_translation
WHERE LEN(product_category_name_english) >
(
    SELECT
        AVG(CAST(LEN(product_category_name_english) AS FLOAT))
        + 3 * STDEV(CAST(LEN(product_category_name_english) AS FLOAT))
    FROM dbo.Product_category_name_translation
);

-- p) Same Portuguese and English category name

SELECT *
FROM dbo.Product_category_name_translation
WHERE LOWER(product_category_name) =
      LOWER(product_category_name_english);

-- q) One Portuguese category mapped to multiple English categories

SELECT
    product_category_name,
    COUNT(DISTINCT product_category_name_english) AS TranslationCount
FROM dbo.Product_category_name_translation
GROUP BY product_category_name
HAVING COUNT(DISTINCT product_category_name_english) > 1;

-- r) One English category mapped to multiple Portuguese categories

SELECT
    product_category_name_english,
    COUNT(DISTINCT product_category_name) AS CategoryCount
FROM dbo.Product_category_name_translation
GROUP BY product_category_name_english
HAVING COUNT(DISTINCT product_category_name) > 1;


-- Products

-- a) Null values

SELECT
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS NullProductID,
    SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) AS NullCategoryName,
    SUM(CASE WHEN product_name_lenght IS NULL THEN 1 ELSE 0 END) AS NullNameLength,
    SUM(CASE WHEN product_description_lenght IS NULL THEN 1 ELSE 0 END) AS NullDescriptionLength,
    SUM(CASE WHEN product_photos_qty IS NULL THEN 1 ELSE 0 END) AS NullPhotosQty,
    SUM(CASE WHEN product_weight_g IS NULL THEN 1 ELSE 0 END) AS NullWeight,
    SUM(CASE WHEN product_length_cm IS NULL THEN 1 ELSE 0 END) AS NullLength,
    SUM(CASE WHEN product_height_cm IS NULL THEN 1 ELSE 0 END) AS NullHeight,
    SUM(CASE WHEN product_width_cm IS NULL THEN 1 ELSE 0 END) AS NullWidth
FROM dbo.Products;

-- b) Duplicate rows

SELECT
    product_id,
    product_category_name,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,
    COUNT(*) AS DuplicateCount
FROM dbo.Products
GROUP BY
    product_id,
    product_category_name,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
HAVING COUNT(*) > 1;

-- c) Duplicate product IDs

SELECT
    product_id,
    COUNT(*) AS DuplicateCount
FROM dbo.Products
GROUP BY product_id
HAVING COUNT(*) > 1;

-- d) Category distribution

SELECT
    product_category_name,
    COUNT(*) AS ProductCount
FROM dbo.Products
GROUP BY product_category_name
ORDER BY ProductCount DESC;

-- e) Distinct categories

SELECT
    COUNT(DISTINCT product_category_name) AS DistinctCategories
FROM dbo.Products;

-- f) Leading/trailing spaces in category names

SELECT *
FROM dbo.Products
WHERE product_category_name IS NOT NULL
AND product_category_name <>
    LTRIM(RTRIM(product_category_name));

-- g) Hidden duplicates in category names

SELECT
    LOWER(LTRIM(RTRIM(product_category_name))) AS CleanCategory,
    COUNT(*) AS Occurrences
FROM dbo.Products
WHERE product_category_name IS NOT NULL
GROUP BY LOWER(LTRIM(RTRIM(product_category_name)))
HAVING COUNT(*) > 1
ORDER BY Occurrences DESC;

-- h) Empty category names

SELECT *
FROM dbo.Products
WHERE product_category_name = '';

-- i) Invalid product name lengths

SELECT *
FROM dbo.Products
WHERE product_name_lenght <= 0;

-- j) Invalid product description lengths

SELECT *
FROM dbo.Products
WHERE product_description_lenght <= 0;

-- k) Invalid photo quantities

SELECT *
FROM dbo.Products
WHERE product_photos_qty < 0;

-- l) Invalid weights

SELECT *
FROM dbo.Products
WHERE product_weight_g <= 0;

-- m) Invalid dimensions

SELECT *
FROM dbo.Products
WHERE product_length_cm <= 0
   OR product_height_cm <= 0
   OR product_width_cm <= 0;

-- n) Product name length statistics

SELECT
    MIN(product_name_lenght) AS MinNameLength,
    MAX(product_name_lenght) AS MaxNameLength,
    AVG(CAST(product_name_lenght AS FLOAT)) AS AvgNameLength
FROM dbo.Products
WHERE product_name_lenght IS NOT NULL;

-- o) Product description length statistics

SELECT
    MIN(product_description_lenght) AS MinDescriptionLength,
    MAX(product_description_lenght) AS MaxDescriptionLength,
    AVG(CAST(product_description_lenght AS FLOAT)) AS AvgDescriptionLength
FROM dbo.Products
WHERE product_description_lenght IS NOT NULL;

-- p) Product weight statistics

SELECT
    MIN(product_weight_g) AS MinWeight,
    MAX(product_weight_g) AS MaxWeight,
    AVG(product_weight_g) AS AvgWeight
FROM dbo.Products
WHERE product_weight_g IS NOT NULL;

-- q) Product dimensions statistics

SELECT
    MIN(product_length_cm) AS MinLength,
    MAX(product_length_cm) AS MaxLength,
    AVG(CAST(product_length_cm AS FLOAT)) AS AvgLength,
    MIN(product_height_cm) AS MinHeight,
    MAX(product_height_cm) AS MaxHeight,
    AVG(CAST(product_height_cm AS FLOAT)) AS AvgHeight,
    MIN(product_width_cm) AS MinWidth,
    MAX(product_width_cm) AS MaxWidth,
    AVG(CAST(product_width_cm AS FLOAT)) AS AvgWidth
FROM dbo.Products;

-- r) Weight outliers

SELECT *
FROM dbo.Products
WHERE product_weight_g >
(
    SELECT
        AVG(product_weight_g)
        + 3 * STDEV(product_weight_g)
    FROM dbo.Products
    WHERE product_weight_g IS NOT NULL
);

-- s) Description length outliers

SELECT *
FROM dbo.Products
WHERE product_description_lenght >
(
    SELECT
        AVG(CAST(product_description_lenght AS FLOAT))
        + 3 * STDEV(CAST(product_description_lenght AS FLOAT))
    FROM dbo.Products
    WHERE product_description_lenght IS NOT NULL
);

-- t) Products without a category

SELECT *
FROM dbo.Products
WHERE product_category_name IS NULL;



