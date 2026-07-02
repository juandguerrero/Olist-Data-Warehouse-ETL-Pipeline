USE OlistWh;

-- DimDate

CREATE TABLE DimDate (
    date_key INT PRIMARY KEY,
    full_date DATE NOT NULL,
    day_number TINYINT NOT NULL,
    month_number TINYINT NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    quarter_number TINYINT NOT NULL,
    year_number SMALLINT NOT NULL
); 

-- DimProduct

CREATE TABLE DimProduct (
    product_key INT IDENTITY(1,1) PRIMARY KEY,
    product_id VARCHAR(50) NOT NULL,
    category_name VARCHAR(100)
);

-- DimSeller

CREATE TABLE DimSeller (
    seller_key INT IDENTITY(1,1) PRIMARY KEY,
    seller_id VARCHAR(50) NOT NULL,
    seller_city VARCHAR(100),
    seller_state CHAR(2)
);

-- DimCustomer

CREATE TABLE DimCustomer (
    customer_key INT IDENTITY(1,1) PRIMARY KEY,
    customer_id VARCHAR(50) NOT NULL,
    customer_unique_id VARCHAR(50) NOT NULL,
    customer_city VARCHAR(100),
    customer_state CHAR(2)
);

-- FactSales

CREATE TABLE FactSales (
    sales_key BIGINT IDENTITY(1,1) PRIMARY KEY,

    order_id VARCHAR(50) NOT NULL,

    date_key INT NOT NULL,
    product_key INT NOT NULL,
    seller_key INT NOT NULL,
    customer_key INT NOT NULL,

    price DECIMAL(10,2) NOT NULL,
    freight_value DECIMAL(10,2) NOT NULL,

    delivery_days INT,
    late_delivery_flag BIT,

    CONSTRAINT FK_FactSales_Date
        FOREIGN KEY (date_key)
        REFERENCES DimDate(date_key),

    CONSTRAINT FK_FactSales_Product
        FOREIGN KEY (product_key)
        REFERENCES DimProduct(product_key),

    CONSTRAINT FK_FactSales_Seller
        FOREIGN KEY (seller_key)
        REFERENCES DimSeller(seller_key),

    CONSTRAINT FK_FactSales_Customer
        FOREIGN KEY (customer_key)
        REFERENCES DimCustomer(customer_key)
);


