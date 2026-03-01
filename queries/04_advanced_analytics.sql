-- ================================================
-- NYC TAXI DATA — ADVANCED ANALYTICS
-- Author: Tharun Kumar Reddy Byreddy
-- Description: Advanced analytical queries for
--              deep business insight extraction
-- ================================================


-- -----------------------------------------------
-- 1. Surge pricing pattern detection
-- -----------------------------------------------
WITH hourly_avg AS (
    SELECT
        EXTRACT(HOUR FROM pickup_datetime)   AS hour_of_day,
        EXTRACT(DOW FROM pickup_datetime)    AS day_of_week,
        ROUND(AVG(fare_amount), 2)           AS avg_fare,
        ROUND(AVG(trip_distance), 2)         AS avg_distance,
        ROUND(AVG(fare_amount /
            NULLIF(trip_distance, 0)), 2)    AS fare_per_mile
    FROM nyc_taxi_trips
    WHERE trip_distance > 0
    GROUP BY hour_of_day, day_of_week
),
overall_avg AS (
    SELECT
        ROUND(AVG(fare_amount /
            NULLIF(trip_distance, 0)), 2)    AS overall_fare_per_mile
    FROM nyc_taxi_trips
    WHERE trip_distance > 0
),
surge_detection AS (
    SELECT
        h.*,
        o.overall_fare_per_mile,
        ROUND(h.fare_per_mile /
            o.overall_fare_per_mile, 2)      AS surge_multiplier,
        CASE
            WHEN h.fare_per_mile >
                o.overall_fare_per_mile*1.5  THEN 'High Surge'
            WHEN h.fare_per_mile >
                o.overall_fare_per_mile*1.2  THEN 'Moderate Surge'
            ELSE 'Normal'
        END                                  AS surge_status
    FROM hourly_avg h
    CROSS JOIN overall_avg o
)
SELECT
    CASE day_of_week
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
    END                                      AS day_name,
    hour_of_day,
    avg_fare,
    fare_per_mile,
    surge_multiplier,
    surge_status
FROM surge_detection
WHERE surge_status != 'Normal'
ORDER BY surge_multiplier DESC;


-- -----------------------------------------------
-- 2. Airport vs city trip comparison
-- -----------------------------------------------
WITH trip_classification AS (
    SELECT
        *,
        CASE
            WHEN pickup_location_id IN (1, 132, 138)
                THEN 'Airport Pickup'
            WHEN dropoff_location_id IN (1, 132, 138)
                THEN 'Airport Dropoff'
            ELSE 'City Trip'
        END                                  AS trip_type
    FROM nyc_taxi_trips
),
trip_comparison AS (
    SELECT
        trip_type,
        COUNT(*)                             AS total_trips,
        ROUND(AVG(fare_amount), 2)           AS avg_fare,
        ROUND(AVG(tip_amount), 2)            AS avg_tip,
        ROUND(AVG(trip_distance), 2)         AS avg_distance,
        ROUND(AVG(tip_amount /
            NULLIF(fare_amount, 0)) * 100,
        2)                                   AS avg_tip_pct,
        ROUND(SUM(fare_amount), 2)           AS total_revenue
    FROM trip_classification
    GROUP BY trip_type
)
SELECT
    *,
    ROUND(100.0 * total_trips /
        SUM(total_trips) OVER (), 2)         AS pct_of_all_trips
FROM trip_comparison
ORDER BY total_revenue DESC;


-- -----------------------------------------------
-- 3. Customer retention proxy analysis
-- -----------------------------------------------
WITH daily_trips AS (
    SELECT
        DATE(pickup_datetime)                AS trip_date,
        COUNT(*)                             AS daily_trips,
        ROUND(SUM(fare_amount), 2)           AS daily_revenue
    FROM nyc_taxi_trips
    GROUP BY trip_date
),
retention_metrics AS (
    SELECT
        trip_date,
        daily_trips,
        daily_revenue,
        LAG(daily_trips, 1) OVER (
            ORDER BY trip_date
        )                                    AS prev_day_trips,
        LAG(daily_trips, 7) OVER (
            ORDER BY trip_date
        )                                    AS same_day_last_week,
        ROUND(100.0 * (daily_trips -
            LAG(daily_trips, 7) OVER (
                ORDER BY trip_date)) /
            NULLIF(LAG(daily_trips, 7) OVER (
                ORDER BY trip_date), 0),
        2)                                   AS wow_growth_pct
    FROM daily_trips
)
SELECT *
FROM retention_metrics
WHERE same_day_last_week IS NOT NULL
ORDER BY trip_date;


-- -----------------------------------------------
-- 4. Revenue concentration analysis (Pareto)
-- -----------------------------------------------
WITH hourly_revenue AS (
    SELECT
        EXTRACT(HOUR FROM pickup_datetime)   AS hour_of_day,
        ROUND(SUM(fare_amount), 2)           AS total_revenue
    FROM nyc_taxi_trips
    GROUP BY hour_of_day
),
pareto AS (
    SELECT
        hour_of_day,
        total_revenue,
        SUM(total_revenue) OVER (
            ORDER BY total_revenue DESC
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        )                                    AS cumulative_revenue,
        SUM(total_revenue) OVER ()           AS grand_total
    FROM hourly_revenue
)
SELECT
    hour_of_day,
    total_revenue,
    cumulative_revenue,
    ROUND(100.0 * cumulative_revenue /
        grand_total, 2)                      AS cumulative_pct,
    CASE
        WHEN cumulative_revenue /
            grand_total <= 0.8               THEN 'Top 80% Revenue'
        ELSE 'Bottom 20% Revenue'
    END                                      AS pareto_segment
FROM pareto
ORDER BY total_revenue DESC;


-- -----------------------------------------------
-- 5. Anomaly detection — unusual fare amounts
-- -----------------------------------------------
WITH fare_stats AS (
    SELECT
        ROUND(AVG(fare_amount), 2)           AS mean_fare,
        ROUND(STDDEV(fare_amount), 2)        AS stddev_fare
    FROM nyc_taxi_trips
    WHERE fare_amount > 0
),
anomalies AS (
    SELECT
        t.*,
        f.mean_fare,
        f.stddev_fare,
        ROUND((t.fare_amount - f.mean_fare) /
            NULLIF(f.stddev_fare, 0), 2)     AS z_score
    FROM nyc_taxi_trips t
    CROSS JOIN fare_stats f
    WHERE t.fare_amount > 0
)
SELECT
    pickup_datetime,
    fare_amount,
    trip_distance,
    passenger_count,
    mean_fare,
    stddev_fare,
    z_score,
    CASE
        WHEN ABS(z_score) > 3 THEN 'Outlier'
        WHEN ABS(z_score) > 2 THEN 'Suspicious'
        ELSE 'Normal'
    END                                      AS anomaly_status
FROM anomalies
WHERE ABS(z_score) > 2
ORDER BY ABS(z_score) DESC
LIMIT 50;


-- -----------------------------------------------
-- 6. Cohort analysis by pickup hour
-- -----------------------------------------------
WITH hour_cohorts AS (
    SELECT
        EXTRACT(HOUR FROM pickup_datetime)   AS pickup_hour,
        DATE(pickup_datetime)                AS trip_date,
        COUNT(*)                             AS trips,
        ROUND(AVG(fare_amount), 2)           AS avg_fare,
        ROUND(AVG(tip_amount /
            NULLIF(fare_amount, 0))*100, 2)  AS tip_rate_pct
    FROM nyc_taxi_trips
    WHERE fare_amount > 0
    GROUP BY pickup_hour, trip_date
),
cohort_summary AS (
    SELECT
        pickup_hour,
        COUNT(DISTINCT trip_date)            AS active_days,
        ROUND(AVG(trips), 1)                 AS avg_daily_trips,
        ROUND(AVG(avg_fare), 2)              AS avg_fare,
        ROUND(AVG(tip_rate_pct), 2)          AS avg_tip_rate_pct,
        ROUND(SUM(trips * avg_fare), 2)      AS estimated_revenue
    FROM hour_cohorts
    GROUP BY pickup_hour
)
SELECT
    pickup_hour,
    active_days,
    avg_daily_trips,
    avg_fare,
    avg_tip_rate_pct,
    estimated_revenue,
    RANK() OVER (
        ORDER BY estimated_revenue DESC
    )                                        AS revenue_rank
FROM cohort_summary
ORDER BY revenue_rank;
