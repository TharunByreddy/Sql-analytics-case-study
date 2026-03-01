-- ================================================
-- NYC TAXI DATA — WINDOW FUNCTIONS
-- Author: Tharun Kumar Reddy Byreddy
-- Description: Advanced window function queries
--              for ranking and running totals
-- ================================================


-- -----------------------------------------------
-- 1. Rank drivers by total revenue (daily)
-- -----------------------------------------------
SELECT
    DATE(pickup_datetime)              AS trip_date,
    vendor_id,
    COUNT(*)                           AS daily_trips,
    ROUND(SUM(fare_amount), 2)         AS daily_revenue,
    RANK() OVER (
        PARTITION BY DATE(pickup_datetime)
        ORDER BY SUM(fare_amount) DESC
    )                                  AS revenue_rank
FROM nyc_taxi_trips
GROUP BY trip_date, vendor_id
ORDER BY trip_date, revenue_rank;


-- -----------------------------------------------
-- 2. Running total revenue by day
-- -----------------------------------------------
SELECT
    trip_date,
    daily_revenue,
    ROUND(SUM(daily_revenue) OVER (
        ORDER BY trip_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2)                              AS running_total_revenue,
    ROUND(AVG(daily_revenue) OVER (
        ORDER BY trip_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2)                              AS rolling_7day_avg
FROM (
    SELECT
        DATE(pickup_datetime)          AS trip_date,
        ROUND(SUM(fare_amount), 2)     AS daily_revenue
    FROM nyc_taxi_trips
    GROUP BY trip_date
) daily_totals
ORDER BY trip_date;


-- -----------------------------------------------
-- 3. Percentile ranking of trips by fare
-- -----------------------------------------------
SELECT
    pickup_datetime,
    fare_amount,
    trip_distance,
    NTILE(4) OVER (
        ORDER BY fare_amount
    )                                  AS fare_quartile,
    PERCENT_RANK() OVER (
        ORDER BY fare_amount
    )                                  AS fare_percentile,
    ROUND(AVG(fare_amount) OVER (
        PARTITION BY EXTRACT(HOUR FROM pickup_datetime)
    ), 2)                              AS hourly_avg_fare
FROM nyc_taxi_trips
WHERE fare_amount > 0
ORDER BY fare_amount DESC
LIMIT 100;


-- -----------------------------------------------
-- 4. Top 10% revenue-generating hours
-- -----------------------------------------------
WITH hourly_revenue AS (
    SELECT
        EXTRACT(HOUR FROM pickup_datetime) AS hour_of_day,
        COUNT(*)                            AS total_trips,
        ROUND(SUM(fare_amount), 2)          AS total_revenue,
        NTILE(10) OVER (
            ORDER BY SUM(fare_amount)
        )                                   AS revenue_decile
    FROM nyc_taxi_trips
    GROUP BY hour_of_day
)
SELECT
    hour_of_day,
    total_trips,
    total_revenue,
    revenue_decile
FROM hourly_revenue
WHERE revenue_decile = 10
ORDER BY total_revenue DESC;


-- -----------------------------------------------
-- 5. Trip lag/lead analysis — consecutive trips
-- -----------------------------------------------
SELECT
    vendor_id,
    pickup_datetime,
    fare_amount,
    LAG(fare_amount) OVER (
        PARTITION BY vendor_id
        ORDER BY pickup_datetime
    )                                  AS prev_fare,
    LEAD(fare_amount) OVER (
        PARTITION BY vendor_id
        ORDER BY pickup_datetime
    )                                  AS next_fare,
    fare_amount - LAG(fare_amount) OVER (
        PARTITION BY vendor_id
        ORDER BY pickup_datetime
    )                                  AS fare_change
FROM nyc_taxi_trips
ORDER BY vendor_id, pickup_datetime
LIMIT 100;


-- -----------------------------------------------
-- 6. Cumulative trip count per hour
-- -----------------------------------------------
SELECT
    EXTRACT(HOUR FROM pickup_datetime) AS hour_of_day,
    COUNT(*)                            AS hourly_trips,
    SUM(COUNT(*)) OVER (
        ORDER BY EXTRACT(HOUR FROM pickup_datetime)
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                   AS cumulative_trips,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM nyc_taxi_trips
GROUP BY hour_of_day
ORDER BY hour_of_day;


-- -----------------------------------------------
-- 7. First and last trip of each day
-- -----------------------------------------------
SELECT DISTINCT
    DATE(pickup_datetime)              AS trip_date,
    FIRST_VALUE(fare_amount) OVER (
        PARTITION BY DATE(pickup_datetime)
        ORDER BY pickup_datetime
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    )                                  AS first_trip_fare,
    LAST_VALUE(fare_amount) OVER (
        PARTITION BY DATE(pickup_datetime)
        ORDER BY pickup_datetime
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    )                                  AS last_trip_fare
FROM nyc_taxi_trips
ORDER BY trip_date;
