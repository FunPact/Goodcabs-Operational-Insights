/*Business Request 1: City-Level Fare and Trip Summary Report*/
USE trips_db;
SELECT 
    dc.city_name,
    COUNT(ft.trip_id) AS total_trips,
    AVG(ft.fare_amount / ft.distance_travelled_km) AS avg_fare_per_km,
    AVG(ft.fare_amount) AS avg_fare_per_trip,
    (COUNT(ft.trip_id) * 100.0 / SUM(COUNT(ft.trip_id)) OVER()) AS percentagefact_trips_contribution_to_total_trips
FROM 
    trips_db.fact_trips ft
JOIN 
    trips_db.dim_city dc
ON 
    ft.city_id = dc.city_id
GROUP BY 
    dc.city_name;
    
    /*Business Request 2: Monthly City-Level Trips Target Performance Report*/
    SELECT 
    dc.city_name,
    dd.month_name,
    COUNT(ft.trip_id) AS actual_trips,
    mt.total_target_trips AS target_trips,
    CASE 
        WHEN COUNT(ft.trip_id) > mt.total_target_trips THEN 'Above Target'
        ELSE 'Below Target'
    END AS performance_status,
    ((COUNT(ft.trip_id) - mt.total_target_trips) * 100.0 / mt.total_target_trips) AS percentage_difference
FROM 
    trips_db.fact_trips ft
JOIN 
    trips_db.dim_city dc
ON 
    ft.city_id = dc.city_id
JOIN 
    trips_db.dim_date dd
ON 
    ft.date = dd.date
JOIN 
    targets_db.monthly_target_trips mt
ON 
    ft.city_id = mt.city_id AND dd.start_of_month = mt.month
GROUP BY 
    dc.city_name, dd.month_name, mt.total_target_trips;*/
    
    /*Business Request 3: City-Level Repeat Passenger Trip Frequency Report
    WITH RepeatPassengerTotals AS (
    SELECT 
        dc.city_name,
        SUM(drt.repeat_passenger_count) AS total_repeat_passengers
    FROM 
        trips_db.dim_repeat_trip_distribution drt
    JOIN 
        trips_db.dim_city dc
    ON 
        drt.city_id = dc.city_id
    GROUP BY 
        dc.city_name
)
SELECT 
    rpt.city_name,
    SUM(CASE WHEN drt.trip_count = '2-Trips' THEN drt.repeat_passenger_count ELSE 0 END) * 100.0 / rpt.total_repeat_passengers AS `2-Trips`,
    SUM(CASE WHEN drt.trip_count = '3-Trips' THEN drt.repeat_passenger_count ELSE 0 END) * 100.0 / rpt.total_repeat_passengers AS `3-Trips`,
    SUM(CASE WHEN drt.trip_count = '4-Trips' THEN drt.repeat_passenger_count ELSE 0 END) * 100.0 / rpt.total_repeat_passengers AS `4-Trips`,
    SUM(CASE WHEN drt.trip_count = '5-Trips' THEN drt.repeat_passenger_count ELSE 0 END) * 100.0 / rpt.total_repeat_passengers AS `5-Trips`,
    SUM(CASE WHEN drt.trip_count = '6-Trips' THEN drt.repeat_passenger_count ELSE 0 END) * 100.0 / rpt.total_repeat_passengers AS `6-Trips`,
    SUM(CASE WHEN drt.trip_count = '7-Trips' THEN drt.repeat_passenger_count ELSE 0 END) * 100.0 / rpt.total_repeat_passengers AS `7-Trips`,
    SUM(CASE WHEN drt.trip_count = '8-Trips' THEN drt.repeat_passenger_count ELSE 0 END) * 100.0 / rpt.total_repeat_passengers AS `8-Trips`,
    SUM(CASE WHEN drt.trip_count = '9-Trips' THEN drt.repeat_passenger_count ELSE 0 END) * 100.0 / rpt.total_repeat_passengers AS `9-Trips`,
    SUM(CASE WHEN drt.trip_count = '10-Trips' THEN drt.repeat_passenger_count ELSE 0 END) * 100.0 / rpt.total_repeat_passengers AS `10-Trips`
FROM 
    trips_db.dim_repeat_trip_distribution drt
JOIN 
    RepeatPassengerTotals rpt
ON 
    drt.city_id = rpt.city_id
GROUP BY 
    rpt.city_name, rpt.total_repeat_passengers;
    
    /*Business Request 4: Identify Cities with Highest and Lowest Total New Passengers*/
    WITH city_rankings AS (
    SELECT 
        dc.city_name,
        SUM(fps.new_passengers) AS total_new_passengers,
        RANK() OVER (ORDER BY SUM(fps.new_passengers) DESC) AS rank_highest,
        RANK() OVER (ORDER BY SUM(fps.new_passengers)) AS rank_lowest
    FROM 
        trips_db.fact_passenger_summary fps
    JOIN 
        trips_db.dim_city dc
    ON 
        fps.city_id = dc.city_id
    GROUP BY 
        dc.city_name
)
SELECT 
    city_name, 
    total_new_passengers,
    CASE 
        WHEN rank_highest <= 3 THEN 'Top 3'
        WHEN rank_lowest <= 3 THEN 'Bottom 3'
        ELSE NULL
    END AS city_category
FROM 
    city_rankings
WHERE 
    rank_highest <= 3 OR rank_lowest <= 3;
    
/*Business Request 5: Identify Month with Highest Revenue for Each City*/
WITH city_revenue AS (
    SELECT 
        dc.city_name,
        dd.month_name,
        SUM(ft.fare_amount) AS monthly_revenue,
        SUM(SUM(ft.fare_amount)) OVER (PARTITION BY dc.city_name) AS total_city_revenue
    FROM 
        trips_db.fact_trips ft
    JOIN 
        trips_db.dim_city dc
    ON 
        ft.city_id = dc.city_id
    JOIN 
        trips_db.dim_date dd
    ON 
        ft.date = dd.date
    GROUP BY 
        dc.city_name, dd.month_name
),
max_revenue_per_city AS (
    SELECT 
        city_name,
        MAX(monthly_revenue) AS max_monthly_revenue
    FROM 
        city_revenue
    GROUP BY 
        city_name
)
SELECT 
    cr.city_name,
    cr.month_name AS highest_revenue_month,
    cr.monthly_revenue,
    (cr.monthly_revenue * 100.0 / cr.total_city_revenue) AS percentage_contribution
FROM 
    city_revenue cr
JOIN 
    max_revenue_per_city mrc
ON 
    cr.city_name = mrc.city_name AND cr.monthly_revenue = mrc.max_monthly_revenue;
    
    /*Business Request 6: Repeat Passenger Rate Analysis*/
    SELECT 
    dc.city_name,
    dd.month_name,
    fps.total_passengers,
    fps.repeat_passengers,
    (fps.repeat_passengers * 100.0 / fps.total_passengers) AS monthly_repeat_passenger_rate,
    (SUM(fps.repeat_passengers) OVER (PARTITION BY dc.city_name) * 100.0 / SUM(fps.total_passengers) OVER (PARTITION BY dc.city_name)) AS city_repeat_passenger_rate
FROM 
    trips_db.fact_passenger_summary fps
JOIN 
    trips_db.dim_city dc
ON 
    fps.city_id = dc.city_id
JOIN 
    trips_db.dim_date dd
ON 
    fps.month = dd.start_of_month;

