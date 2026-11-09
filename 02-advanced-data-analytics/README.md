# 📈 Part 2: Advanced Data Analytics

<img width="1376" height="768" alt="phase 2" src="https://github.com/user-attachments/assets/837f4858-23ad-4a31-a7a9-218901366856" />


## 📌 Executive Summary
This directory contains **Part 2** of the SQL Retail Sales Analytics portfolio. While Phase 1 focused on understanding the baseline data via Exploratory Data Analysis (EDA), this phase tackles complex business logic using **Advanced T-SQL techniques**.

We utilize Common Table Expressions (CTEs), advanced Window Functions (`SUM() OVER`, `LAG()`, `RANK()`), date truncation, and frame boundaries to model metrics change-over-time, analyze cumulative growth, track Year-over-Year (YoY) performance, and segment product categories. The final output provides production-ready analytical views suitable for direct consumption by BI dashboards (e.g., Power BI, Tableau).

---

## 🗺️ Phase 2 Analytical Scope

| Step # | Analysis Focus | Key SQL Concepts & Frameworks Applied |
| :---: | :--- | :--- |
| **7** | **Change-Over-Time Analysis** | Time-series aggregation, `DATETRUNC()`, `YEAR()`, `MONTH()` |
| **8** | **Cumulative Analysis** | Month-over-Month (MoM) Running Totals via CTEs & `SUM() OVER(ORDER BY ...)` |
| **9** | **Performance & Trend Analysis** | Year-over-Year (YoY) Sales Growth, Product Velocity (`LAG()`, analytical frames) |
| **10** | **Part-to-Whole Analysis** | Proportional category percentage contribution to total revenue |
| **11** | **Data Segmentation** | Dynamic product price tiering & customer grouping (placeholder for future RFM) |
| **12** | **Production Reporting Views** | Analytical View encapsulation for Business Intelligence consumption |

---

## 🛠️ Step-by-Step Advanced SQL Queries & Insights

### 1️⃣ Change-Over-Time Analysis (Monthly Granularity)
We begin by establishing a time-series aggregation to analyze monthly revenue granularity over the full operational lifespan.

```sql
-- Calculate Monthly Revenue Granularity
SELECT 
    DATETRUNC(month, s.order_date) AS order_month,
    SUM(s.sales_amount) AS total_revenue,
    COUNT(DISTINCT s.order_number) AS total_orders
FROM gold.fact_sales s
WHERE s.order_date IS NOT NULL
GROUP BY DATETRUNC(month, s.order_date)
ORDER BY order_month ASC;

```

#### 📊 Sample Output

| order_month | total_revenue | total_orders |
| --- | --- | --- |
| **2010-01-01** | $650,450 | 720 |
| **2010-02-01** | $580,200 | 690 |
| **...** | **...** | **...** |
| **2013-12-01** | $1,250,900 | 1,150 |

> **💡 Key Insight:** Revenue shows distinct seasonality. Analyzing the raw monthly figures prepares us for cumulative and Year-over-Year calculations.

---

### 2️⃣ Cumulative Analysis: Month-over-Month Running Totals

To track corporate growth trajectory without collapsing monthly data, we use CTEs and partitioned windowed sums.

```sql
-- Compute Cumulative Month-over-Month (MoM) Running Total
WITH MonthlySales AS (
    SELECT 
        DATETRUNC(month, s.order_date) AS order_month,
        SUM(s.sales_amount) AS total_revenue
    FROM gold.fact_sales s
    WHERE s.order_date IS NOT NULL
    GROUP BY DATETRUNC(month, s.order_date)
)
SELECT 
    order_month,
    total_revenue,
    SUM(total_revenue) OVER (ORDER BY order_month ASC) AS running_total_revenue
FROM MonthlySales
ORDER BY order_month ASC;

```

#### 📊 Sample Output

| order_month | total_revenue | running_total_revenue |
| --- | --- | --- |
| **2010-01-01** | $650,450 | **$650,450** |
| **2010-02-01** | $580,200 | **$1,230,650** |
| **2010-03-01** | $610,000 | **$1,840,650** |

> **💡 Key Insight:** Tracking the cumulative growth trajectory provides a clear view of business acceleration. Leaders can pinpoint exactly when revenue doubled relative to the historical start.

---

### 3️⃣ Performance & YoY Analysis: Product Velocity & LAG()

Evaluating product annual momentum against historical performance metrics, identifying expanding versus decaying product lifecycles. We combine `LAG()` for direct YoY comparison with partitioned averages (`AVG() OVER`) to establish baseline performance.

```sql
-- Analyze Yearly Product Momentum & YoY Growth
WITH YearlyProductSales AS (
    SELECT
        p.product_name,
        YEAR(s.order_date) AS order_year,
        SUM(s.sales_amount) AS total_sales
    FROM gold.fact_sales s
    LEFT JOIN gold.dim_products p 
        ON s.product_key = p.product_key
    WHERE s.order_date IS NOT NULL
    GROUP BY p.product_name, YEAR(s.order_date)
)
SELECT
    product_name,
    order_year,
    total_sales,
    -- Lifespan product average across all operational years
    AVG(total_sales) OVER (PARTITION BY product_name) AS avg_product_sales_volume,
    -- Previous year's revenue for direct comparison
    LAG(total_sales) OVER (PARTITION BY product_name ORDER BY order_year ASC) AS prev_year_sales,
    -- YoY Growth Variance
    total_sales - LAG(total_sales) OVER (PARTITION BY product_name ORDER BY order_year ASC) AS yoy_growth_variance
FROM YearlyProductSales
ORDER BY product_name, order_year;

```

#### 📊 Sample Output

| product_name | order_year | total_sales | avg_product_sales_volume | prev_year_sales | yoy_growth_variance |
| --- | --- | --- | --- | --- | --- |
| **Bike-X1 Black** | 2011 | $550,000 | $580,000 | *NULL* | *NULL* |
| **Bike-X1 Black** | 2022 | $720,000 | $580,000 | $550,000 | **+$170,000** |
| **Bike-X1 Black** | 2023 | $680,000 | $580,000 | $720,000 | **-$40,000** |

> **💡 Key Insight:** Combining `LAG()` with partitioned averages exposes product lifecycle stages—distinguishing mature flagship lines (steady YoY) from emerging or decaying inventory items (high variance).

---

## 🛠️ Advanced SQL Skill Stack (Phase 2)

* **Database Engine:** Microsoft SQL Server (T-SQL)
* **Advanced Query Structuring:** Common Table Expressions (CTEs), Subqueries.
* **Window Functions:** Advanced use of analytical aggregates (`SUM() OVER()`, `AVG() OVER()`), offset functions (`LAG()`), and ranking functions (`RANK()`).
* **Data Modeling Techniques:** Year-over-Year (YoY) metrics, change-over-time trend modeling, cumulative total calculations, and proportional segmentation.

---

## 📂 Sub-Directory Structure Context

```text
sql-retail-sales-analysis-portfolio/
│
├── 📁 01-exploratory-data-analysis/
│   ├── 📄 01_eda_queries.sql
│   └── 📄 README.md
│
├── 📁 02-advanced-data-analytics/
│   ├── 📄 01_advanced_queries.sql          <-- Full Analytical Script File
│   └── 📄 README.md                        <-- (This Documentation File)
│
└── 📄 README.md                            <-- Master Portfolio README (Overview)

```

```

```
