# 🛒 Comprehensive Retail Sales Data Analytics (SQL Server)

Welcome to the **Retail Sales Analytics Portfolio**. This repository presents an end-to-end data analysis journey using **SQL Server (T-SQL)** on an enterprise retail dataset (Star Schema). 

The project follows a structured 12-step data analytics roadmap divided into two core phases: **Exploratory Data Analysis (EDA)** and **Advanced Data Analytics**.

---

## 🗺️ Analytical Roadmap

<img width="1408" height="768" alt="Prev_sql Project" src="https://github.com/user-attachments/assets/ff654f33-0886-4d1d-9356-dd03cd572bf3" />

---

## 📂 Repository Structure

```text
sql-retail-sales-analytics/
│
├── 📁 01-exploratory-data-analysis/
│   ├── 01_database_exploration.sql
│   ├── 02_dimensions_exploration.sql
│   ├── 03_date_exploration.sql
│   ├── 04_measures_exploration.sql
│   ├── 05_magnitude_analysis.sql
│   └── 06_ranking_analysis.sql
│
├── 📁 02-advanced-data-analytics/
│   ├── 07_change_over_time_trends.sql
│   ├── 08_cumulative_analysis.sql
│   ├── 09_performance_analysis.sql
│   ├── 10_part_to_whole.sql
│   ├── 11_data_segmentation.sql
│   └── 12_final_reporting.sql
│
└── 📄 README.md
```

---

## 📊 Phase 1: Exploratory Data Analysis (EDA)

### 1️⃣ Database Exploration
Inspect database metadata, schema tables, and column structures to understand data architecture.

```sql
-- Explore All Tables in Database
SELECT TABLE_SCHEMA, TABLE_NAME, TABLE_TYPE 
FROM INFORMATION_SCHEMA.TABLES;
```

#### 📋 Output Result:
| TABLE_SCHEMA | TABLE_NAME | TABLE_TYPE |
| :--- | :--- | :--- |
| gold | dim_customers | BASE TABLE |
| gold | dim_products | BASE TABLE |
| gold | fact_sales | BASE TABLE |

💡 **Key Insight:** The database follows a clean **Star Schema** model with a centralized fact table (`fact_sales`) surrounded by two key dimensions (`dim_customers` and `dim_products`).

---

### 2️⃣ Dimensions Exploration
Understand categorical attributes and column types across dimension tables.

```sql
-- Explore Columns of Customer Dimension
SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'dim_customers';
```

#### 📋 Output Result:
| COLUMN_NAME | DATA_TYPE | Attribute Type |
| :--- | :--- | :--- |
| customer_key | int | Surrogate Key |
| customer_id | int | Business Key |
| first_name | nvarchar | Dimension |
| last_name | nvarchar | Dimension |
| country | nvarchar | Geographical Dimension |
| gender | nvarchar | Demographic Dimension |
| birthdate | date | Temporal Boundary |

💡 **Key Insight:** High-value demographic vectors available for cohort analysis include `country`, `gender`, and age calculated from `birthdate`.

---

### 3️⃣ Date Exploration
Identify the historical lifespan boundaries of the business and demographic spans.

```sql
-- Sales Order Date Range (Lifespan Boundary)
SELECT 
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date,
    DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS order_range_months
FROM gold.fact_sales;
```

#### 📋 Output Result:
| first_order_date | last_order_date | order_range_months |
| :--- | :--- | :--- |
| 2010-12-29 | 2014-01-28 | 37 |

```sql
-- Customer Age Span Profiling
SELECT
    MIN(birthdate) AS oldest_birthdate,
    DATEDIFF(YEAR, MIN(birthdate), GETDATE()) AS oldest_age,
    MAX(birthdate) AS youngest_birthdate,
    DATEDIFF(YEAR, MAX(birthdate), GETDATE()) AS youngest_age
FROM gold.dim_customers;
```

#### 📋 Output Result:
| oldest_birthdate | oldest_age | youngest_birthdate | youngest_age |
| :--- | :--- | :--- | :--- |
| 1916-02-10 | 110 | 1986-06-25 | 40 |

💡 **Key Insights:**
- The transactional dataset spans exactly **37 months (~3 years)** of continuous business operations.
- The customer age profile ranges between **40 and 110 years old**, indicating a mature demographic base with high purchasing power.

---

### 4️⃣ Measures Exploration & Executive Reporting
Compute core quantitative KPIs and consolidate them into a single dynamic executive report using `UNION ALL`.

```sql
-- Dynamic Executive Summary KPI Report
SELECT 'Total Sales ($)' AS Measure_Name, SUM(sales_amount) AS Measure_Value FROM gold.fact_sales
UNION ALL
SELECT 'Quantity Sold', SUM(quantity) FROM gold.fact_sales 
UNION ALL
SELECT 'Average Selling Price ($)', ROUND(AVG(price), 2) FROM gold.fact_sales
UNION ALL
SELECT 'Total Orders', COUNT(DISTINCT order_number) FROM gold.fact_sales 
UNION ALL
SELECT 'Total Products Catalog', COUNT(product_id) FROM gold.dim_products
UNION ALL
SELECT 'Total Registered Customers', COUNT(customer_id) FROM gold.dim_customers
UNION ALL
SELECT 'Active Customers (With Orders)', COUNT(DISTINCT customer_key) FROM gold.fact_sales;
```

#### 📋 Output Result:
| Measure_Name | Measure_Value |
| :--- | :--- |
| Total Sales ($) | 29,358,677 |
| Quantity Sold | 60,398 |
| Average Selling Price ($) | 486.09 |
| Total Orders | 27,659 |
| Total Products Catalog | 295 |
| Total Registered Customers | 18,484 |
| Active Customers (With Orders) | 18,444 |

💡 **Key Insights:**
- **Customer Conversion:** Out of 18,484 registered customers, **99.78% (18,444)** have placed at least one order, showing an exceptionally high activation rate.
- **Basket Size:** An average selling price of **$486.09** suggests the business specializes in medium-to-high ticket retail products (e.g., electronics or specialized equipment).

---

### 5️⃣ Magnitude Analysis
Analyze metrics across categorical dimensions to understand business distribution.

```sql
-- Total Revenue and Quantity by Product Category
SELECT
    p.category,
    SUM(f.sales_amount) AS total_revenue,
    SUM(f.quantity) AS total_quantity_sold
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p ON p.product_key = f.product_key
GROUP BY p.category
ORDER BY total_revenue DESC;
```

#### 📋 Output Result:
| category | total_revenue | total_quantity_sold |
| :--- | :--- | :--- |
| Bikes | $28,318,144 | 15,205 |
| Accessories | $700,608 | 36,086 |
| Clothing | $339,925 | 9,107 |

💡 **Key Insights:**
- **Pareto Principle (80/20 Rule):** The **Bikes** category drives **96.4% of total revenue**, despite making up only ~25% of total units sold.
- **Volume vs. Value:** Accessories account for the highest unit volume (36,086 units) but generate lower revenue due to smaller price points.

---

### 6️⃣ Ranking Analysis
Identify top revenue generators and bottom laggards using Window Functions (`ROW_NUMBER` / `RANK`).

```sql
-- Top 5 Products by Revenue (Window Ranking)
SELECT * 
FROM (
    SELECT 
        p.product_name,
        SUM(s.sales_amount) AS total_revenue,
        ROW_NUMBER() OVER (ORDER BY SUM(s.sales_amount) DESC) AS rank_num
    FROM gold.dim_products p
    LEFT JOIN gold.fact_sales s ON p.product_key = s.product_key
    GROUP BY p.product_name
) ranked
WHERE rank_num <= 5;
```

#### 📋 Output Result:
| product_name | total_revenue | rank_num |
| :--- | :--- | :--- |
| Mountain-200 Black, 38 | $1,374,256 | 1 |
| Mountain-200 Black, 42 | $1,353,099 | 2 |
| Mountain-200 Silver, 38 | $1,281,424 | 3 |
| Mountain-200 Silver, 42 | $1,241,130 | 4 |
| Road-150 Red, 48 | $1,205,820 | 5 |

💡 **Key Insights:**
- The **Mountain-200** product line dominates top performance, filling 4 out of the top 5 revenue spots. 
- Inventory optimization strategies should prioritize maintaining high stock levels for these specific models to avoid revenue loss.

---

## 📈 Phase 2: Advanced Data Analytics

### 1- Change-Over-Time Trends
Analyze Sales Performance Over Time:
```sql
SELECT 
    YEAR(s.order_date) AS order_Year,
    MONTH(s.order_date) AS order_month,
    SUM(s.sales_amount) AS T_sales,
    COUNT(DISTINCT s.customer_key) AS T_customers,
    SUM(QUANTITY) AS T_quantity
FROM gold.fact_sales s
GROUP BY 
    YEAR(s.order_date),
    MONTH(s.order_date)
HAVING YEAR(s.order_date) IS NOT NULL
ORDER BY 
    YEAR(s.order_date),
    MONTH(s.order_date);
```

---

### 2- Cumulative Analysis
Calculate total sales per month, the running total of sales over time, and the moving average:
```sql
WITH Sales_monthly AS 
(	
    SELECT 
        DATETRUNC(Month, s.order_date) AS Order_date,
        SUM(sales_amount) AS Total_Sales,
        AVG(sales_amount) AS AVG_Sales
    FROM gold.fact_sales s
    WHERE DATETRUNC(Month, s.order_date) IS NOT NULL
    GROUP BY DATETRUNC(Month, s.order_date)
)
SELECT 
    order_date,
    AVG_Sales,
    AVG(AVG_Sales) OVER (ORDER BY order_date) AS Moving_AVG,
    Total_sales,
    SUM(Total_sales) OVER (ORDER BY order_date) AS Running_Total_Sales
FROM Sales_monthly;
```

---

### 3- Performance Analysis
Analyze the yearly performance of products by comparing each product's sales to both its average sales performance and the previous year's sales:
```sql
WITH Yearly_sales AS (
    SELECT 
        p.product_name,
        YEAR(s.order_date) AS order_Year,
        SUM(sales_amount) AS Current_Sales
    FROM gold.fact_sales s
    LEFT JOIN gold.dim_products p
        ON s.product_key = p.product_key
    WHERE order_date IS NOT NULL
    GROUP BY	
        p.product_name,
        YEAR(s.order_date)
)
SELECT 
    *,
    AVG(Current_Sales) OVER(PARTITION BY Product_name) AS AVG_Sales,
    (Current_Sales - AVG(Current_Sales) OVER(PARTITION BY Product_name)) AS Dif_AVG,
    CASE 
        WHEN (Current_Sales - AVG(Current_Sales) OVER(PARTITION BY Product_name)) > 0 THEN 'Above_AVG'
        WHEN (Current_Sales - AVG(Current_Sales) OVER(PARTITION BY Product_name)) < 0 THEN 'Below_AVG'
        ELSE '= AVG'
    END AS AVG_change,
    LAG(current_sales) OVER(PARTITION BY Product_name ORDER BY product_name, order_Year) AS Previous_Yearly_sales,
    Current_sales - LAG(current_sales) OVER(PARTITION BY Product_name ORDER BY product_name, order_Year) AS PY_Dif,
    CASE 
        WHEN (Current_Sales - LAG(current_sales) OVER(PARTITION BY Product_name ORDER BY product_name, order_Year)) > 0 THEN 'Above_Prev'
        WHEN (Current_Sales - LAG(current_sales) OVER(PARTITION BY Product_name ORDER BY product_name, order_Year)) < 0 THEN 'Below_Prev'	
        WHEN (Current_Sales - LAG(current_sales) OVER(PARTITION BY Product_name ORDER BY product_name, order_Year)) IS NULL THEN 'No_Prev_Year'	
        ELSE '= AVG'
    END AS PY_change
FROM Yearly_sales
ORDER BY 
    product_name,
    order_Year;
```

---

### 4- Part-to-Whole Proportional Analysis
Analyze how an individual part performs compared to the overall business (Which categories contribute the most to overall sales?):
```sql
WITH category_sales AS (
    SELECT
        p.category,
        SUM(s.sales_amount) AS T_sales_f_category
    FROM gold.fact_sales S	
    LEFT JOIN gold.dim_products P		
        ON s.product_key = p.product_key
    GROUP BY p.category
) 
SELECT 
    category,
    T_sales_f_category,
    SUM(T_sales_f_category) OVER() AS Total_sales,
    CONCAT(ROUND((CAST(T_sales_f_category AS FLOAT) / SUM(T_sales_f_category) OVER()) * 100, 2), '%') AS Percentage_of_total
FROM category_sales
ORDER BY T_sales_f_category DESC;
```

---

### 5- Data Segmentation

#### (1) Segment products into cost ranges and count how many products fall into each segment:
```sql
WITH EDA AS (
    SELECT 
        Product_key,
        SUM(cost) OVER(PARTITION BY Product_key ORDER BY cost DESC) AS costs,
        MAX(cost) OVER() AS Max_,
        MIN(cost) OVER() AS Min_,
        AVG(cost) OVER() AS avg_,
        CASE 
            WHEN cost < 100 THEN 'below 100'
            WHEN cost BETWEEN 100 AND 500 THEN '100-500'
            WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
            ELSE 'above 1000'
        END AS cost_range,
        CASE 
            WHEN cost >= 1000 THEN 'need to check'
            WHEN cost > 500 THEN 'High costing'
            WHEN cost <= 500 THEN 'Permited limit'           
        END AS cost_seg 
    FROM gold.dim_products
)           
SELECT 
    Cost_Seg,
    Cost_Range,
    COUNT(PRODUCT_key) AS T_Products
FROM EDA
GROUP BY 
    cost_range,
    cost_seg
ORDER BY T_Products DESC;
```

#### (2) Group customers into three segments based on spending behavior (VIP, Regular, New):
```sql
WITH EDA AS (
    SELECT 
        c.customer_key,
        SUM(s.sales_amount) AS Total_Spending,
        MIN(s.order_date) AS First_order,
        MAX(s.order_date) AS LAST_order,
        DATEDIFF(month, MIN(s.order_date), MAX(s.order_date)) AS Life_span
    FROM gold.fact_sales s
    LEFT JOIN gold.dim_customers c
        ON s.customer_key = c.customer_key
    GROUP BY c.customer_key
)
SELECT 
    Spending_Behavior,
    COUNT(customer_key) AS Total_number_of_customers
FROM (
    SELECT
        customer_key,
        CASE
            WHEN Life_span >= 12 AND Total_Spending > 5000 THEN 'VIP'
            WHEN Life_span >= 12 AND Total_Spending <= 5000 THEN 'Regular'
            ELSE 'New'
        END AS Spending_Behavior
    FROM EDA
) n
GROUP BY Spending_Behavior
ORDER BY Total_number_of_customers DESC;
```

---

### 6- Reporting Views

#### Customer Report View (`gold.report_customers`):
```sql
CREATE VIEW gold.report_customers AS								
WITH Base_Query AS (			
    SELECT 
        s.order_number,
        s.product_key,
        s.order_date,
        s.sales_amount,
        s.quantity,
        c.customer_key,
        c.customer_number,
        CONCAT(c.first_name, ' ', c.last_name) AS Full_name,
        DATEDIFF(year, c.birthdate, GETDATE()) AS Customer_age
    FROM gold.fact_sales s
    LEFT JOIN gold.dim_customers c
        ON s.customer_key = c.customer_key
    WHERE s.order_date IS NOT NULL 
),
CUTOMER_AGGREGATION AS (
    SELECT 
        customer_key,
        customer_number,
        Full_name,
        Customer_age,
        COUNT(DISTINCT order_number) AS T_N_of_orders,
        SUM(sales_amount) AS T_sales,
        SUM(quantity) AS T_N_QUANTITY,
        COUNT(product_key) AS T_N_OF_PRODUCT,
        MAX(ORDER_DATE) AS LAST_ORDER_DATE,
        DATEDIFF(month, MIN(order_date), MAX(order_date)) AS Life_span
    FROM Base_Query
    GROUP BY 
        customer_key,
        customer_number,
        Full_name,
        Customer_age
)
SELECT
    customer_key,
    customer_number,
    Full_name,
    Customer_age,
    CASE 
        WHEN Customer_age < 20 THEN 'UNDER 20'
        WHEN Customer_age BETWEEN 20 AND 29 THEN '20-29'
        WHEN Customer_age BETWEEN 30 AND 39 THEN '30-39'
        WHEN Customer_age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50 AND ABOVE'
    END AS AGE_GROUP,
    CASE
        WHEN Life_span >= 12 AND T_sales > 5000 THEN 'VIP'
        WHEN Life_span >= 12 AND T_sales <= 5000 THEN 'Regular'
        ELSE 'New'
    END AS Spending_Behavior,
    T_N_of_orders,
    T_sales,
    T_N_QUANTITY,
    T_N_OF_PRODUCT,
    LAST_ORDER_DATE,
    DATEDIFF(MONTH, LAST_ORDER_DATE, GETDATE()) AS RECENCY,
    Life_span,
    CASE
        WHEN T_sales = 0 THEN 0
        ELSE T_sales / T_N_of_orders
    END AS AVG_ORDER_VALUE,
    CASE
        WHEN Life_span = 0 THEN T_sales
        ELSE T_sales / Life_span 
    END AS AVERAGE_MONTHLY_SPEND
FROM CUTOMER_AGGREGATION;
```

#### Product Report View (`gold.report_products`):
```sql
CREATE VIEW gold.report_products AS
WITH base_query AS (
    SELECT
        f.order_number,
        f.order_date,
        f.customer_key,
        f.sales_amount,
        f.quantity,
        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    WHERE order_date IS NOT NULL
),
product_aggregations AS (
    SELECT
        product_key,
        product_name,
        category,
        subcategory,
        cost,
        DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan,
        MAX(order_date) AS last_sale_date,
        COUNT(DISTINCT order_number) AS total_orders,
        COUNT(DISTINCT customer_key) AS total_customers,
        SUM(sales_amount) AS total_sales,
        SUM(quantity) AS total_quantity,
        ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)), 1) AS avg_selling_price
    FROM base_query
    GROUP BY 
        product_key,
        product_name,
        category,
        subcategory,
        cost
)
SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    last_sale_date,
    DATEDIFF(MONTH, last_sale_date, GETDATE()) AS recency_in_months,
    CASE
        WHEN total_sales > 50000 THEN 'High-Performer'
        WHEN total_sales >= 10000 THEN 'Mid-Range'
        ELSE 'LowFerformer'
    END AS produdSsegment,
    lifespan,
    total_orders,
    total_sales,
    total_quantity,
    total_customers,
    avg_selling_price,
    CASE
        WHEN total_orders = 0 THEN 0
        ELSE total_sales / total_orders
    END AS avg_order_revenue,
    CASE
        WHEN lifespan = 0 THEN total_sales
        ELSE total_sales / lifespan
    END AS avg_monthly_revenue
FROM product_aggregations;
```

---

## 🛠️ Tools & Technologies Used
- **Database Engine:** Microsoft SQL Server (T-SQL)
- **Advanced SQL Functions:** Window Functions (`SUM OVER`, `ROW_NUMBER`, `LAG`, `AVG OVER`), CTEs, `DATETRUNC`, Aggregate Functions, Metadata Profiling.
- **Documentation & Data Storytelling:** GitHub Markdown, Mermaid Flowcharts.
