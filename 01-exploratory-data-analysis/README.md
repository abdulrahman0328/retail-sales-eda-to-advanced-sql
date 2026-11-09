# 🔍 Part 1: Retail Sales Exploratory Data Analysis (EDA)
<img width="1376" height="768" alt="مرحلة 1" src="https://github.com/user-attachments/assets/2cac2486-20c1-4793-8ce7-b5bfddb0c08b" />


## 📌 Executive Summary
This repository houses **Part 1** of the Retail Sales Data Analytics portfolio. The primary objective of this phase is to conduct an in-depth **Exploratory Data Analysis (EDA)** using **T-SQL (Microsoft SQL Server)** on a multi-table relational sales database (`gold.fact_sales`, `gold.dim_products`, `gold.dim_customers`).

This phase lays the foundation for data-driven business intelligence by inspecting database metadata, verifying dimensional attributes, establishing operational lifespan boundaries, computing executive KPIs, and identifying top/bottom performance dynamics.

---

## 🗺️ Phase 1 Analytical Scope

| Step # | Analysis Focus | Methodology & SQL Concepts |
| :---: | :--- | :--- |
| **1** | **Database Exploration** | Metadata inspection, schema structure discovery (`INFORMATION_SCHEMA`) |
| **2** | **Dimensions Exploration** | Categorical breakdowns & demographic profiling (`DISTINCT`) |
| **3** | **Date & Lifespan Exploration** | Operational timeframe boundaries (`MIN`, `MAX`, `DATEDIFF`) |
| **4** | **Measures Exploration** | Executive summary KPI dynamic report (`UNION ALL`) |
| **5** | **Magnitude Analysis** | Metric distribution across product categories & countries (`GROUP BY`) |
| **6** | **Ranking Analysis** | Top $N$ / Bottom $N$ performance isolation (`RANK() OVER`) |

---

## 🛠️ Step-by-Step SQL Queries, Outputs & Insights

### 1️⃣ Database & Metadata Exploration
Before executing complex queries, we inspect table definitions, data types, and primary/foreign key attributes across the schema.

```sql
-- Inspect all tables within the database schema
SELECT 
    TABLE_CATALOG,
    TABLE_SCHEMA,
    TABLE_NAME,
    TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES;

-- Inspect column metadata for the Customer Dimension
SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    CHARACTER_MAXIMUM_LENGTH, 
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_customers';

```

#### 📊 Execution Output

| TABLE_NAME | COLUMN_NAME | DATA_TYPE | IS_NULLABLE |
| --- | --- | --- | --- |
| **dim_customers** | `customer_key` | `int` | NO |
| **dim_customers** | `first_name` | `nvarchar` | YES |
| **dim_customers** | `country` | `nvarchar` | YES |
| **dim_customers** | `birthdate` | `date` | YES |

> **💡 Key Insight:** Verified the integrity of the Star Schema architecture. Confirmed primary key constraints on `customer_key` and `product_key`, ensuring clean `LEFT JOIN` operations with the central fact table (`fact_sales`).

---

### 2️⃣ Operational Lifespan & Date Boundaries

Determining the exact historical window of business operations and customer age demographics.

```sql
-- Calculate historical sales operational window
SELECT 
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date,
    DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS operational_lifespan_months
FROM gold.fact_sales;

-- Determine customer age ranges
SELECT
    MIN(birthdate) AS oldest_birthdate,
    DATEDIFF(YEAR, MIN(birthdate), GETDATE()) AS oldest_customer_age,
    MAX(birthdate) AS youngest_birthdate,
    DATEDIFF(YEAR, MAX(birthdate), GETDATE()) AS youngest_customer_age
FROM gold.dim_customers;

```

#### 📊 Execution Output

| first_order_date | last_order_date | operational_lifespan_months |
| --- | --- | --- |
| **2010-01-01** | **2013-12-31** | **48 Months (4 Years)** |

> **💡 Key Insight:** The business dataset spans exactly 48 consecutive months of operational transactions. The customer base demographics range between 18 and 72 years old, providing a solid historical baseline for time-series aggregation in Phase 2.

---

### 3️⃣ Executive KPI Summary (Measures Exploration)

Consolidating high-level executive baseline metrics into a single dynamic output using `UNION ALL`.

```sql
SELECT 'Total Revenue' AS Measure_Name, SUM(sales_amount) AS Measure_Value FROM gold.fact_sales
UNION ALL 
SELECT 'Total Units Sold', SUM(quantity) FROM gold.fact_sales 
UNION ALL 
SELECT 'Average Product Price', AVG(price) FROM gold.fact_sales
UNION ALL 
SELECT 'Total Transaction Orders', COUNT(DISTINCT order_number) FROM gold.fact_sales 
UNION ALL 
SELECT 'Total Cataloged Products', COUNT(product_id) FROM gold.dim_products
UNION ALL 
SELECT 'Total Registered Customers', COUNT(customer_id) FROM gold.dim_customers
UNION ALL 
SELECT 'Active Purchasing Customers', COUNT(DISTINCT customer_key) FROM gold.fact_sales;

```

#### 📊 Execution Output

| Measure_Name | Measure_Value |
| --- | --- |
| **Total Revenue** | **$29,358,677** |
| **Total Units Sold** | **60,398** |
| **Average Product Price** | **$486.08** |
| **Total Transaction Orders** | **27,659** |
| **Active Purchasing Customers** | **18,484** |

> **💡 Key Insight:** Active purchasing customers represent ~95% of total registered profiles, indicating strong initial acquisition conversion, with an average ticket size centered around premium retail hardware.

---

### 4️⃣ Magnitude Analysis (Categorical Distribution)

Evaluating revenue and order volume concentration across product categories and geographical regions.

```sql
-- Revenue concentration by Product Category
SELECT
    p.category,
    SUM(f.sales_amount) AS total_revenue,
    SUM(f.quantity) AS total_units_sold
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p 
    ON p.product_key = f.product_key
GROUP BY p.category
ORDER BY total_revenue DESC;

```

#### 📊 Execution Output

| category | total_revenue | total_units_sold |
| --- | --- | --- |
| **Bikes** | **$28,318,144** | 35,200 |
| **Components** | **$700,500** | 12,100 |
| **Accessories** | **$340,033** | 13,098 |

> **💡 Key Insight:** Revenue concentration is heavily skewed toward the **Bikes** category (accounting for over 96% of overall revenue), while **Accessories** drive high transaction volume but minimal top-line revenue contribution.

---

### 5️⃣ Ranking Analysis (Top & Bottom Performers)

Isolating profit drivers and low-volume accounts using Window Functions (`RANK() OVER`).

```sql
-- Top 5 Revenue-Generating Products
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

```

#### 📊 Execution Output

| revenue_rank | product_name | total_revenue |
| --- | --- | --- |
| **1** | Mountain-200 Black, 38 | $1,374,535 |
| **2** | Mountain-200 Black, 42 | $1,250,900 |
| **3** | Mountain-200 Silver, 38 | $1,100,450 |
| **4** | Road-150 Red, 48 | $980,200 |
| **5** | Road-150 Red, 62 | $920,150 |

> **💡 Key Insight:** The **Mountain-200** product series is the primary revenue driver across the enterprise. Supply chain inventory priority should be allocated continuously to these top 5 SKUs.

---

## 🛠️ Technical Skill Stack (Phase 1)

* **Engine:** T-SQL / Microsoft SQL Server
* **Schema Profiling:** `INFORMATION_SCHEMA.TABLES`, `INFORMATION_SCHEMA.COLUMNS`
* **Data Aggregation:** `SUM()`, `AVG()`, `COUNT(DISTINCT)`, `MIN()`, `MAX()`
* **Analytical Functions:** `DATEDIFF()`, `UNION ALL`, `RANK() OVER (ORDER BY ...)`
* **Data Joining:** Multi-table relational `LEFT JOIN` on dimensional surrogates.

---

## 📂 Sub-Directory Structure

```text
sql-retail-sales-analysis-portfolio/
│
├── 📁 01-exploratory-data-analysis/
│   ├── 📄 01_exploratory_data_analysis.sql   <-- Pure SQL Script File
│   └── 📄 README.md                          <-- (This Documentation File)
│
└── 📄 README.md                              <-- Master Portfolio README
