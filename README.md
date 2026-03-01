# 🗄️ SQL Analytics Case Study — NYC Taxi Data

![Python](https://img.shields.io/badge/Python-3.9-blue)
![SQL](https://img.shields.io/badge/SQL-Advanced-orange)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Database-blue)
![Status](https://img.shields.io/badge/Status-Active-brightgreen)

## 📌 Overview
End-to-end SQL analytics project on 50,000+ NYC Taxi trip records,
demonstrating advanced query techniques and business insight extraction
using window functions, CTEs, subqueries, and aggregations — visualized
with Python.

---

## 🎯 Problem Statement
Extract meaningful business insights from large-scale transportation data
using advanced SQL — identifying revenue patterns, surge pricing windows,
tip behavior, and driver performance tiers.

---

## 📁 Project Structure
```
sql-analytics-case-study/
├── queries/
│   ├── 01_basic_analysis.sql       # Foundational queries
│   ├── 02_window_functions.sql     # Ranking and running totals
│   ├── 03_cte_analysis.sql         # Multi-step CTE queries
│   └── 04_advanced_analytics.sql  # Surge, anomaly, cohort analysis
├── notebooks/
│   └── analysis_visualizations.ipynb  # Python visualizations
├── results/                        # Output charts
├── data/                           # Dataset directory
├── requirements.txt
└── README.md
```

---

## 🔬 SQL Techniques Covered

| File | Techniques |
|------|-----------|
| 01_basic_analysis | GROUP BY, aggregations, CASE, ORDER BY |
| 02_window_functions | RANK, DENSE_RANK, LAG, LEAD, NTILE, running totals |
| 03_cte_analysis | Multi-step CTEs, rolling averages, MoM growth |
| 04_advanced_analytics | Surge detection, anomaly detection, cohort analysis, Pareto |

---

## 📊 Key Insights

| Insight | Finding |
|---------|---------|
| Peak revenue hours | 6PM — 9PM on weekdays |
| Top payment method | Credit Card (67% of trips) |
| Tip rate | 70% of passengers tip |
| Airport trips avg fare | 2.3x higher than city trips |
| Top 20% of hours | Generate 80% of total revenue |
| Surge pricing windows | Friday & Saturday 10PM — 2AM |

---

## 🗂️ Query Highlights

### Window Function — Rolling 7-Day Revenue
```sql
SELECT
    trip_date,
    total_revenue,
    ROUND(AVG(total_revenue) OVER (
        ORDER BY trip_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2) AS rolling_7day_avg
FROM daily_revenue
ORDER BY trip_date;
```

### CTE — Month over Month Growth
```sql
WITH monthly_revenue AS (
    SELECT DATE_TRUNC('month', pickup_datetime) AS month,
           ROUND(SUM(fare_amount), 2) AS total_revenue
    FROM nyc_taxi_trips GROUP BY month
)
SELECT month, total_revenue,
    ROUND(100.0 * (total_revenue -
        LAG(total_revenue) OVER (ORDER BY month)) /
        NULLIF(LAG(total_revenue) OVER (ORDER BY month), 0), 2
    ) AS mom_growth_pct
FROM monthly_revenue ORDER BY month;
```

---

## 🛠️ Tech Stack
| Category | Tools |
|----------|-------|
| Language | Python 3.9, SQL |
| Database | PostgreSQL, BigQuery |
| Visualization | Matplotlib, Seaborn, Plotly |
| Data | Pandas, NumPy |
| Stats | SciPy |

---

## 🚀 How to Run
```bash
# 1. Clone the repo
git clone https://github.com/TharunByreddy/sql-analytics-case-study.git
cd sql-analytics-case-study

# 2. Install dependencies
pip install -r requirements.txt

# 3. Run the notebook
jupyter notebook notebooks/analysis_visualizations.ipynb

# 4. Run SQL queries in PostgreSQL
psql -U postgres -f queries/01_basic_analysis.sql
psql -U postgres -f queries/02_window_functions.sql
psql -U postgres -f queries/03_cte_analysis.sql
psql -U postgres -f queries/04_advanced_analytics.sql
```

---

## 📬 Author
**Tharun Kumar Reddy Byreddy**
M.S. Statistical Data Science | San Francisco State University
[LinkedIn](https://www.linkedin.com/in/tharun-kumar-reddy-byeddy-801290215/) |
[GitHub](https://github.com/TharunByreddy)
