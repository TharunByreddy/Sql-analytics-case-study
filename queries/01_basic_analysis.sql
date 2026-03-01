-- ================================================
-- NYC TAXI DATA — BASIC ANALYSIS
-- Author: Tharun Kumar Reddy Byreddy
-- Description: Foundational queries for exploring
--              NYC Taxi trip data
-- ================================================


-- -----------------------------------------------
-- 1. Total trips and revenue overview
-- -----------------------------------------------
SELECT
    COUNT(*)                          AS total_trips,
    ROUND(SUM(fare_amount), 2)        AS total_revenue,
    ROUND(AVG(fare_amount), 2)        AS avg_fare,
    ROUND(MIN(fare_amount), 2)        AS min_fare,
    ROUND(MAX(fare_amount), 2)        AS max_fare,
    ROUND(AVG(trip_distance), 2)      AS avg_distance,
    ROUND(AVG(tip_amount), 2)         AS avg_tip
FROM nyc_taxi_trips;


-- -----------------------------------------------
-- 2. Trip count by payment type
-- -----------------------------------------------
SELECT
    payment_type,
    COUNT(*)                          AS total_trips,
    ROUND(SUM(fare_amount), 2)        AS total_revenue,
    ROUND(AVG(fare_amount), 2)        AS avg_fare,
    ROUND(AVG(tip_amount), 2)         AS avg_tip
FROM nyc_taxi_trips
GROUP BY payment_type
ORDER BY total_trips DESC;


-- -----------------------------------------------
-- 3. Trips by hour of day
-- -----------------------------------------------
SELECT
    EXTRACT(HOUR FROM pickup_datetime) AS hour_of_day,
    COUNT(*)                            AS total_trips,
    ROUND(AVG(fare_amount), 2)          AS avg_fare,
    ROUND(SUM(fare_amount), 2)          AS total_revenue
FROM nyc_taxi_trips
GROUP BY hour_of_day
ORDER BY hour_of_day;


-- -----------------------------------------------
-- 4. Trips by day of week
-- -----------------------------------------------
SELECT
    TO_CHAR(pickup_datetime, 'Day')    AS day_of_week,
    EXTRACT(DOW FROM pickup_datetime)  AS day_number,
    COUNT(*)                           AS total_trips,
    ROUND(AVG(fare_amount), 2)         AS avg_fare,
    ROUND(SUM(fare_amount), 2)         AS total_revenue
FROM nyc_taxi_trips
GROUP BY day_of_week, day_number
ORDER BY day_number;


-- -----------------------------------------------
-- 5. Trips by passenger count
-- -----------------------------------------------
SELECT
    passenger_count,
    COUNT(*)                          AS total_trips,
    ROUND(AVG(fare_amount), 2)        AS avg_fare,
    ROUND(AVG(tip_amount), 2)         AS avg_tip,
    ROUND(AVG(trip_distance), 2)      AS avg_distance
FROM nyc_taxi_trips
WHERE passenger_count > 0
GROUP BY passenger_count
ORDER BY passenger_count;


-- -----------------------------------------------
-- 6. Revenue by vendor
-- -----------------------------------------------
SELECT
    vendor_id,
    COUNT(*)                          AS total_trips,
    ROUND(SUM(fare_amount), 2)        AS total_revenue,
    ROUND(AVG(fare_amount), 2)        AS avg_fare,
    ROUND(AVG(trip_distance), 2)      AS avg_distance
FROM nyc_taxi_trips
GROUP BY vendor_id
ORDER BY total_revenue DESC;


-- -----------------------------------------------
-- 7. Distance buckets analysis
-- -----------------------------------------------
SELECT
    CASE
        WHEN trip_distance < 1  THEN '0-1 miles'
        WHEN trip_distance < 3  THEN '1-3 miles'
        WHEN trip_distance < 5  THEN '3-5 miles'
        WHEN trip_distance < 10 THEN '5-10 miles'
        ELSE '10+ miles'
    END                               AS distance_bucket,
    COUNT(*)                          AS total_trips,
    ROUND(AVG(fare_amount), 2)        AS avg_fare,
    ROUND(AVG(tip_amount), 2)         AS avg_tip
FROM nyc_taxi_trips
WHERE trip_distance > 0
GROUP BY distance_bucket
ORDER BY MIN(trip_distance);


-- -----------------------------------------------
-- 8. Top 10 most expensive trips
-- -----------------------------------------------
SELECT
    pickup_datetime,
    dropoff_datetime,
    trip_distance,
    fare_amount,
    tip_amount,
    total_amount,
    passenger_count
FROM nyc_taxi_trips
ORDER BY fare_amount DESC
LIMIT 10;
