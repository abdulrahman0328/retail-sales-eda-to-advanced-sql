# 🛒 Comprehensive Retail Sales Data Analytics (SQL Server)

Welcome to the **Retail Sales Analytics Portfolio**. This repository presents an end-to-end data analysis journey using **SQL Server (T-SQL)** on an enterprise retail dataset (Star Schema). 

The project follows a structured 12-step data analytics roadmap divided into two core phases: **Exploratory Data Analysis (EDA)** and **Advanced Data Analytics**.

---

## 🗺️ Analytical Roadmap

| Phase | Step # | Analysis Type | Focus & Methodology |
| :--- | :---: | :--- | :--- |
| **Phase 1: Exploratory Data Analysis** | **1** | **Database Exploration** | Inspect metadata, tables, schemas, and object architecture. |
| | **2** | **Dimensions Exploration** | Categorical breakdown, data types, and attribute profiling. |
| | **3** | **Date Exploration** | Lifespan boundaries (`MIN`/`MAX` dates) & demographic age spans. |
| | **4** | **Measures Exploration** | Executive KPI summary report using dynamic `UNION ALL`. |
| | **5** | **Magnitude Analysis** | Metric distribution across product categories, countries & gender. |
| | **6** | **Ranking Analysis** | Top $N$ / Bottom $N$ performance identification using `RANK()`. |
| **Phase 2: Advanced Data Analytics** | **7** | **Change-Over-Time** | Historical trends & monthly revenue granularity (`DATETRUNC`). |
| | **8** | **Cumulative Analysis** | Month-over-Month running totals using CTEs & `SUM() OVER()`. |
| | **9** | **Performance Analysis** | YoY growth analysis & moving averages (`LAG()` & `AVG() OVER`). |
| | **10** | **Part-to-Whole Analysis** | Category revenue percentage contributions to total sales. |
| | **11** | **Data Segmentation** | Customer RFM grouping & product price tiering. |
| | **12** | **Final Reporting & Views** | Production-ready database views for BI integration. |

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
* The transactional dataset spans exactly **37 months (~3 years)** of continuous business operations.
* The customer age profile ranges between **40 and 110 years old**, indicating a mature demographic base with high purchasing power.

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
* **Customer Conversion:** Out of 18,484 registered customers, **99.78% (18,444)** have placed at least one order, showing an exceptionally high activation rate.
* **Basket Size:** An average selling price of **$486.09** suggests the business specializes in medium-to-high ticket retail products (e.g., electronics or specialized equipment).

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
* **Pareto Principle (80/20 Rule):** The **Bikes** category drives **96.4% of total revenue**, despite making up only ~25% of total units sold.
* **Volume vs. Value:** Accessories account for the highest unit volume (36,086 units) but generate lower revenue due to smaller price points.

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
* The **Mountain-200** product line dominates top performance, filling 4 out of the top 5 revenue spots. 
* Inventory optimization strategies should prioritize maintaining high stock levels for these specific models to avoid revenue loss.

---

## 📈 Phase 2: Advanced Data Analytics

### 7️⃣ Change-Over-Time Analysis
Examine temporal trends and monthly revenue fluctuations.

```sql
-- Monthly Sales Trend Analysis
SELECT 
    DATETRUNC(month, order_date) AS order_month,
    SUM(sales_amount) AS total_sales
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month, order_date)
ORDER BY order_month ASC;
```

#### 📋 Output Result (Sample Extract):
| order_month | total_sales |
| :--- | :--- |
| 2011-01-01 | $469,479 |
| 2011-02-01 | $466,892 |
| 2011-03-01 | $484,725 |
| ... | ... |
| 2013-12-01 | $1,048,223 |

💡 **Key Insight:** Monthly revenue shows strong steady growth over the 3-year period, scaling from ~$460K/month in early 2011 to over **$1M/month** by late 2013.

---

### 8️⃣ Cumulative Analysis (Running Totals)
Compute month-over-month running totals of retail sales using CTEs and `SUM() OVER ()`.

```sql
WITH MonthlySales AS (
    SELECT 
        DATETRUNC(month, s.order_date) AS Order_Month,
        SUM(sales_amount) AS Total_Sales
    FROM gold.fact_sales s
    WHERE DATETRUNC(month, s.order_date) IS NOT NULL
    GROUP BY DATETRUNC(month, s.order_date)
)
SELECT 
    Order_Month,
    Total_Sales,
    SUM(Total_Sales) OVER (ORDER BY Order_Month ASC) AS Running_Total_Sales
FROM MonthlySales
ORDER BY Order_Month ASC;
```

#### 📋 Output Result (Sample Extract):
| Order_Month | Total_Sales | Running_Total_Sales |
| :--- | :--- | :--- |
| 2011-01-01 | $469,479 | $469,479 |
| 2011-02-01 | $466,892 | $936,371 |
| 2011-03-01 | $484,725 | $1,421,096 |
| ... | ... | ... |
| 2014-01-01 | $643,837 | **$29,358,677** |

💡 **Key Insight:** Running totals track cumulative business velocity. The company hit its first **$10 Million** cumulative milestone mid-2012 and reached **~$29.35 Million** by the end of the analyzed timeframe.

---

### 9️⃣ Performance Analysis (YoY Growth & Moving Averages)
Compare product yearly performance against historical averages and previous year performance using `LAG()` and `AVG() OVER()`.

```sql
WITH YearlyProductSales AS (
    SELECT
        p.product_name,
        YEAR(s.order_date) AS Order_Year,
        SUM(s.sales_amount) AS Total_Sales
    FROM gold.fact_sales s
    LEFT JOIN gold.dim_products p ON s.product_key = p.product_key
    WHERE s.order_date IS NOT NULL
    GROUP BY p.product_name, YEAR(s.order_date)
)
SELECT
    product_name,
    Order_Year,
    Total_Sales,
    ROUND(AVG(Total_Sales) OVER (PARTITION BY product_name), 2) AS Avg_Product_Sales,
    LAG(Total_Sales) OVER (PARTITION BY product_name ORDER BY Order_Year ASC) AS Prev_Year_Sales,
    Total_Sales - LAG(Total_Sales) OVER (PARTITION BY product_name ORDER BY Order_Year ASC) AS YoY_Growth
FROM YearlyProductSales
ORDER BY product_name, Order_Year;
```

#### 📋 Output Result (Sample Extract):
| product_name | Order_Year | Total_Sales | Avg_Product_Sales | Prev_Year_Sales | YoY_Growth |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Mountain-100 Silver, 44 | 2011 | $350,120 | $412,300 | *NULL* | *NULL* |
| Mountain-100 Silver, 44 | 2012 | $474,480 | $412,300 | $350,120 | +$124,360 |
| Mountain-100 Silver, 44 | 2013 | $412,300 | $412,300 | $474,480 | -$62,180 |

💡 **Key Insights:**
* Using `LAG()` allows real-time year-over-year growth calculation (`YoY_Growth`) without requiring complex self-joins.
* Products with negative YoY growth in 2013 can be quickly flagged for product refresh or promotional campaigns.

---

### 🔟 Part-to-Whole Analysis
*(In Progress - Analyzing category proportional contributions to total overall revenue)*

### 1️⃣1️⃣ Data Segmentation
*(In Progress - Customer RFM Segmentation & Product Price Tiering)*

### 1️⃣2️⃣ Final Reporting & Analytical Views
*(In Progress - Building modular views for BI tool consumption)*

---

## 🛠️ Tools & Technologies Used
* **Database Engine:** Microsoft SQL Server (T-SQL)
* **Advanced SQL Functions:** Window Functions (`SUM OVER`, `ROW_NUMBER`, `LAG`, `AVG OVER`), CTEs, `DATETRUNC`, Aggregate Functions, Metadata Profiling.
* **Documentation & Data Storytelling:** GitHub Markdown, Mermaid Flowcharts.
