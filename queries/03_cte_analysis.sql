-- ================================================
-- NYC TAXI DATA — CTE ANALYSIS
-- Author: Tharun Kumar Reddy Byreddy
-- Description: Complex CTEs for multi-step
--              business insight extraction
-- ================================================


-- -----------------------------------------------
-- 1. Rolling 7-day average revenue
-- -----------------------------------------------
WITH daily_revenue AS (
    SELECT
        DATE(pickup_datetime)         AS trip_date,
        COUNT(*)                      AS total_trips,
        ROUND(SUM(fare_amount), 2)    AS total_revenue,
        ROUND(AVG(fare_amount), 2)    AS avg_fare
    FROM nyc_taxi_trips
    GROUP BY trip_date
),
rolling_avg AS (
    SELECT
        trip_date,
        total_trips,
        total_revenue,
        avg_fare,
        ROUND(AVG(total_revenue) OVER (
            ORDER BY trip_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ), 2)                         AS rolling_7day_avg,
        ROUND(AVG(total_trips) OVER (
            ORDER BY trip_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ), 0)                         AS rolling_7day_trips
    FROM daily_revenue
)
SELECT *
FROM rolling_avg
ORDER BY trip_date;


-- -----------------------------------------------
-- 2. High value vs low value trip segmentation
-- -----------------------------------------------
WITH trip_segments AS (
    SELECT
        *,
        CASE
            WHEN fare_amount >= 50  THEN 'Premium'
            WHEN fare_amount >= 20  THEN 'Standard'
            WHEN fare_amount >= 10  THEN 'Budget'
            ELSE 'Micro'
        END                           AS trip_segment
    FROM nyc_taxi_trips
    WHERE fare_amount > 0
),
segment_summary AS (
    SELECT
        trip_segment,
        COUNT(*)                      AS total_trips,
        ROUND(SUM(fare_amount), 2)    AS total_revenue,
        ROUND(AVG(fare_amount), 2)    AS avg_fare,
        ROUND(AVG(tip_amount), 2)     AS avg_tip,
        ROUND(AVG(trip_distance), 2)  AS avg_distance,
        ROUND(100.0 * COUNT(*) /
            SUM(COUNT(*)) OVER (), 2) AS pct_of_trips
    FROM trip_segments
    GROUP BY trip_segment
)
SELECT *
FROM segment_summary
ORDER BY avg_fare DESC;


-- -----------------------------------------------
-- 3. Driver performance tiers
-- -----------------------------------------------
WITH vendor_stats AS (
    SELECT
        vendor_id,
        DATE(pickup_datetime)         AS trip_date,
        COUNT(*)                      AS daily_trips,
        ROUND(SUM(fare_amount), 2)    AS daily_revenue,
        ROUND(AVG(tip_amount), 2)     AS avg_tip
    FROM nyc_taxi_trips
    GROUP BY vendor_id, trip_date
),
vendor_totals AS (
    SELECT
        vendor_id,
        SUM(daily_trips)              AS total_trips,
        ROUND(SUM(daily_revenue), 2)  AS total_revenue,
        ROUND(AVG(avg_tip), 2)        AS overall_avg_tip,
        ROUND(AVG(daily_trips), 1)    AS avg_daily_trips
    FROM vendor_stats
    GROUP BY vendor_id
),
vendor_ranked AS (
    SELECT
        *,
        NTILE(3) OVER (
            ORDER BY total_revenue DESC
        )                             AS performance_tier
    FROM vendor_totals
)
SELECT
    vendor_id,
    total_trips,
    total_revenue,
    overall_avg_tip,
    avg_daily_trips,
    CASE performance_tier
        WHEN 1 THEN 'Top Performer'
        WHEN 2 THEN 'Mid Performer'
        WHEN 3 THEN 'Low Performer'
    END                               AS performance_tier
FROM vendor_ranked
ORDER BY total_revenue DESC;


-- -----------------------------------------------
-- 4. Peak hour identification
-- -----------------------------------------------
WITH hourly_stats AS (
    SELECT
        EXTRACT(HOUR FROM pickup_datetime)  AS hour_of_day,
        EXTRACT(DOW FROM pickup_datetime)   AS day_of_week,
        COUNT(*)                             AS total_trips,
        ROUND(SUM(fare_amount), 2)           AS total_revenue,
        ROUND(AVG(fare_amount), 2)           AS avg_fare
    FROM nyc_taxi_trips
    GROUP BY hour_of_day, day_of_week
),
peak_hours AS (
    SELECT
        hour_of_day,
        day_of_week,
        total_trips,
        total_revenue,
        avg_fare,
        RANK() OVER (
            PARTITION BY day_of_week
            ORDER BY total_trips DESC
        )                                    AS hourly_rank
    FROM hourly_stats
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
    total_trips,
    total_revenue,
    avg_fare
FROM peak_hours
WHERE hourly_rank = 1
ORDER BY day_of_week;


-- -----------------------------------------------
-- 5. Tip behavior analysis
-- -----------------------------------------------
WITH tip_analysis AS (
    SELECT
        *,
        CASE
            WHEN tip_amount = 0               THEN 'No Tip'
            WHEN tip_amount < fare_amount*0.1 THEN 'Low Tip (<10%)'
            WHEN tip_amount < fare_amount*0.2 THEN 'Standard (10-20%)'
            WHEN tip_amount < fare_amount*0.3 THEN 'Good (20-30%)'
            ELSE 'Generous (30%+)'
        END                                   AS tip_category
    FROM nyc_taxi_trips
    WHERE fare_amount > 0
),
tip_summary AS (
    SELECT
        tip_category,
        COUNT(*)                              AS total_trips,
        ROUND(AVG(fare_amount), 2)            AS avg_fare,
        ROUND(AVG(tip_amount), 2)             AS avg_tip,
        ROUND(AVG(trip_distance), 2)          AS avg_distance,
        ROUND(100.0 * COUNT(*) /
            SUM(COUNT(*)) OVER (), 2)         AS pct_of_trips
    FROM tip_analysis
    GROUP BY tip_category
)
SELECT *
FROM tip_summary
ORDER BY avg_tip DESC;


-- -----------------------------------------------
-- 6. Month over month revenue growth
-- -----------------------------------------------
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', pickup_datetime)  AS month,
        COUNT(*)                               AS total_trips,
        ROUND(SUM(fare_amount), 2)             AS total_revenue
    FROM nyc_taxi_trips
    GROUP BY month
),
mom_growth AS (
    SELECT
        month,
        total_trips,
        total_revenue,
        LAG(total_revenue) OVER (
            ORDER BY month
        )                                      AS prev_month_revenue,
        ROUND(100.0 * (total_revenue -
            LAG(total_revenue) OVER (ORDER BY month)) /
            NULLIF(LAG(total_revenue) OVER (ORDER BY month), 0),
        2)                                     AS mom_growth_pct
    FROM monthly_revenue
)
SELECT *
FROM mom_growth
ORDER BY month;
