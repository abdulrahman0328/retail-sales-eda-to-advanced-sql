# 📊 Retail Sales Analytics — Part 2: Advanced SQL Analysis
<img width="1376" height="768" alt="phase 2" src="https://github.com/user-attachments/assets/837f4858-23ad-4a31-a7a9-218901366856" />

> **Data tells the story. SQL helps me find it.**  
> End-to-end advanced data analytics in **T-SQL (Microsoft SQL Server)** — transforming **60,398** raw transaction lines across a star-schema data warehouse into time-series trajectories, product benchmarks, behavioral segments, and production-ready executive reporting views.

---

## 🎯 Project Overview

Following **Part 1 (Exploratory Data Analysis)**—which established schema integrity, baseline KPIs (`$29.36M` total revenue), and category concentration—**Part 2** dives deep into temporal dynamics, cumulative momentum, year-over-year product benchmarking, behavioral segmentation, and reusable reporting layers (`CREATE VIEW`) built for downstream BI dashboards.

### 🏗️ Data Foundation (Star Schema)
* **Fact Table:** `gold.fact_sales` — `60,398` sales lines | `27,659` unique orders | Date range: `Dec 2010` → `Jan 2014`
* **Dimension Tables:** 
  * `gold.dim_customers` — `18,484` customer profiles
  * `gold.dim_products` — `295` catalog items (`130` actively sold, `165` unsold)
* **Data Hygiene Note:** Cumulative time-series totals equal `$29,351,258` (vs. `$29,356,250` overall) because `19` sales lines (`0.03%`) contain `NULL` order dates and are explicitly filtered out during chronological modeling.

---

## 🗺️ The 6-Step Analytical Roadmap

| Step | Module | Core T-SQL Techniques | Key Business Finding |
| :--- | :--- | :--- | :--- |
| **01** | **Change-Over-Time Trends** | `YEAR()`, `MONTH()`, `COUNT(DISTINCT)`, `GROUP BY` | 2013 revenue surged **2.8×** (`$16.34M` vs. `$5.84M` in 2012), driven by order volume rather than ticket size. |
| **02** | **Cumulative Analysis** | `DATETRUNC()`, `SUM() OVER()`, `AVG() OVER()` | Accumulated **$29.35M** across 38 months; **56%** of all historical revenue occurred in 2013 alone. |
| **03** | **Performance Analysis** | `LAG() OVER()`, `AVG() OVER(PARTITION BY)`, `CASE` | **62 of 65** shared products beat their 2012 sales in 2013; every *Mountain-200* variant grew **2.2× to 2.8×**. |
| **04** | **Part-to-Whole Analysis** | `SUM() OVER()`, `CAST()`, `ROUND()`, `CONCAT()` | **Bikes** generate **96.46%** (`$28.32M`) of total revenue; **127 Components** in the catalog have zero sales. |
| **05** | **Data Segmentation** | Multi-CTE pipelines, `DATEDIFF()`, nested `CASE WHEN` | **VIP customers** (`9.0%` of base) drive **36.7%** of total revenue (`$6,510` avg spend). |
| **06** | **Executive Reporting** | `CREATE VIEW`, `NULLIF()`, `GETDATE()`, KPI derivation | Deployed `gold.report_customers` and `gold.report_products` — **66 products** drive **94.2%** of revenue. |

---

## 💻 Complete Production T-SQL Script Library

Below are the exact, production-ready T-SQL queries used in this project. You can copy and execute these directly in SQL Server Management Studio (SSMS) against your database.

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
Calculate the total sales per month, the running total of sales over time, and the moving average:
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

## 🛠️ Tech Stack & SQL Toolkit
* **Database Engine:** Microsoft SQL Server (T-SQL)
* **Architecture:** Medallion Gold Layer (`Star Schema` + `Reporting Views`)
* **Advanced Functions:** Window Functions (`SUM() OVER`, `AVG() OVER`, `LAG()`, `PARTITION BY`), Multi-Step CTEs, Date Arithmetic (`DATETRUNC`, `DATEDIFF`, `GETDATE`), Safe Division (`NULLIF`), Conditional Logic (`CASE WHEN`), and View DDL (`CREATE VIEW`).

---

## 👤 Author

**Abdulrahman Muhammad** — *Junior Data Analyst*  
*Passionate about turning raw relational data into clear, decision-ready business stories with SQL.*  
📫 **Let's connect!**
