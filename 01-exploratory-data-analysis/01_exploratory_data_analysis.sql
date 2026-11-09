===============================================================================
-- Project: Retail Sales Data Analytics Portfolio (Part 1: EDA)
-- Script: 01_exploratory_data_analysis.sql
-- Author: Abdulrahman Muhammad
-- Description: Comprehensive Exploratory Data Analysis (EDA) to inspect metadata, 
--              profile dimensions, determine lifespan boundaries, and aggregate KPIs.
-- Database: SQL Server
===============================================================================

USE DataWarehouse;
GO

-------------------------------------------------------------------------------
-- STEP 1: DATABASE & METADATA EXPLORATION
-- Objective: Inspect tables, schemas, and structural column data types.
-------------------------------------------------------------------------------

-- 1.1 List all tables in the database schema
SELECT 
    TABLE_CATALOG,
    TABLE_SCHEMA,
    TABLE_NAME,
    TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES;

-- 1.2 Inspect column definitions for the Customer dimension table
SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    CHARACTER_MAXIMUM_LENGTH, 
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_customers';

-- 1.3 Inspect column definitions for the Fact Sales table
SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'fact_sales';


-------------------------------------------------------------------------------
-- STEP 2: DIMENSIONS EXPLORATION (Categorical Profiling)
-- Objective: Check distinct categories, demographic fields, and data integrity.
-------------------------------------------------------------------------------

-- 2.1 Retrieve distinct product categories and subcategories
SELECT DISTINCT 
    category, 
    subcategory, 
    product_name
FROM gold.dim_products
ORDER BY category, subcategory;

-- 2.2 Profile customer locations and marital status
SELECT DISTINCT 
    country, 
    marital_status, 
    gender
FROM gold.dim_customers
ORDER BY country;


-------------------------------------------------------------------------------
-- STEP 3: DATE EXPLORATION (Temporal Boundaries & Lifespan)
-- Objective: Identify start/end order dates and customer age spans.
-------------------------------------------------------------------------------

-- 3.1 Calculate historical lifespan of operations
SELECT 
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date,
    DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS total_operational_months
FROM gold.fact_sales;

-- 3.2 Determine youngest and oldest customers
SELECT
    MIN(birthdate) AS oldest_birthdate,
    DATEDIFF(YEAR, MIN(birthdate), GETDATE()) AS oldest_customer_age,
    MAX(birthdate) AS youngest_birthdate,
    DATEDIFF(YEAR, MAX(birthdate), GETDATE()) AS youngest_customer_age
FROM gold.dim_customers;


-------------------------------------------------------------------------------
-- STEP 4: MEASURES EXPLORATION (Executive Summary Dashboard)
-- Objective: Consolidate high-level core business KPIs into a single output.
-------------------------------------------------------------------------------

SELECT 'Total Revenue' AS Measure_Name, SUM(sales_amount) AS Measure_Value FROM gold.fact_sales
UNION ALL 
SELECT 'Total Quantity Sold', SUM(quantity) FROM gold.fact_sales 
UNION ALL 
SELECT 'Average Product Selling Price', AVG(price) FROM gold.fact_sales
UNION ALL 
SELECT 'Total Transaction Orders', COUNT(DISTINCT order_number) FROM gold.fact_sales 
UNION ALL 
SELECT 'Total Unique Products Cataloged', COUNT(product_id) FROM gold.dim_products
UNION ALL 
SELECT 'Total Registered Customers', COUNT(customer_id) FROM gold.dim_customers
UNION ALL 
SELECT 'Active Purchasing Customers', COUNT(DISTINCT customer_key) FROM gold.fact_sales;


-------------------------------------------------------------------------------
-- STEP 5: MAGNITUDE ANALYSIS (Metric Distributions)
-- Objective: Analyze metric splits across categories, countries, and channels.
-------------------------------------------------------------------------------

-- 5.1 Revenue distribution across product categories
SELECT
    p.category,
    SUM(f.sales_amount) AS total_revenue,
    SUM(f.quantity) AS total_units_sold
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p 
    ON p.product_key = f.product_key
GROUP BY p.category
ORDER BY total_revenue DESC;

-- 5.2 Order volume distribution across customer countries
SELECT
    c.country,
    COUNT(DISTINCT f.order_number) AS total_orders,
    SUM(f.sales_amount) AS total_country_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c 
    ON c.customer_key = f.customer_key
GROUP BY c.country
ORDER BY total_country_revenue DESC;


-------------------------------------------------------------------------------
-- STEP 6: RANKING ANALYSIS (Top & Bottom Performers)
-- Objective: Rank products and customers using Window Functions.
-------------------------------------------------------------------------------

-- 6.1 Top 5 revenue-generating products using RANK()
WITH RankedProducts AS (
    SELECT
        p.product_name,
        SUM(f.sales_amount) AS total_revenue,
        RANK() OVER (ORDER BY SUM(f.sales_amount) DESC) AS revenue_rank
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p 
        ON p.product_key = f.product_key
    GROUP BY p.product_name
)
SELECT 
    revenue_rank,
    product_name,
    total_revenue
FROM RankedProducts
WHERE revenue_rank <= 5;

-- 6.2 Bottom 5 customers by total order volume (Retention focus)
SELECT TOP 5
    c.customer_key,
    c.first_name,
    c.last_name,
    COUNT(DISTINCT f.order_number) AS total_orders_placed,
    SUM(f.sales_amount) AS total_spent
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c 
    ON c.customer_key = f.customer_key
GROUP BY 
    c.customer_key,
    c.first_name,
    c.last_name
ORDER BY total_orders_placed ASC, total_spent ASC;
