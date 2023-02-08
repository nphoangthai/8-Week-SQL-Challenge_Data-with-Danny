USE CT2_Pizza_Runner
GO

-- Data Cleaning
DROP TABLE IF EXISTS #customer_orders;
SELECT 
	order_id,
	customer_id,
	pizza_id, 
	CASE
		WHEN exclusions IS null OR exclusions LIKE 'null' THEN ' '
		ELSE exclusions
		END AS exclusions,
	CASE
		WHEN extras IS NULL or extras LIKE 'null' THEN ' '
		ELSE extras
		END AS extras,
	order_time
INTO #customer_orders
FROM customer_orders

--TABLE: runner_orders

exec sp_help runner_orders

--pickup_time - remove nulls and replace with ' '
--distance - remove km and nulls
--duration - remove minutes and nulls
--cancellation - remove NULL and null and replace with ' ' 

DROP TABLE IF EXISTS #runner_orders;
SELECT 
	order_id, 
	runner_id,  
	CASE
		WHEN pickup_time LIKE 'null' THEN ' '
		ELSE pickup_time
		END AS pickup_time,
	CASE
		WHEN distance LIKE 'null' THEN ' '
		WHEN distance LIKE '%km' THEN TRIM('km' from distance)
		ELSE distance
		END AS distance,
	CASE
		WHEN duration LIKE 'null' THEN ' '
		WHEN duration LIKE '%mins' THEN TRIM('mins' from duration)
		WHEN duration LIKE '%minute' THEN TRIM('minute' from duration)
		WHEN duration LIKE '%minutes' THEN TRIM('minutes' from duration)
		ELSE duration
		END AS duration,
	CASE
		WHEN cancellation IS NULL or cancellation LIKE 'null' THEN ' '
		ELSE cancellation
		END AS cancellation
INTO #runner_orders
FROM runner_orders

ALTER TABLE #runner_orders
ALTER COLUMN distance FLOAT

ALTER TABLE #runner_orders
ALTER COLUMN duration INT

ALTER TABLE #runner_orders
ALTER COLUMN pickup_time DATETIME

-- Questions
-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT runner_id,
	CASE
		WHEN registration_date BETWEEN '2021-01-01' AND '2021-01-07' THEN 'Week 1'
		WHEN registration_date BETWEEN '2021-01-08' AND '2021-01-14'THEN 'Week 2'
		ELSE 'Week 3'
		END AS runner_signups
FROM runners
GROUP BY registration_date, runner_id;

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
WITH order_time_cte AS (
		SELECT
			order_id,
			MAX(order_time) AS order_time
		FROM
			#customer_orders
		GROUP BY
			order_id
	),
	time_diff_cte AS (
		SELECT 
			ro.runner_id,
			ro.order_id,
			ro.pickup_time,
			ot.order_time,
			-- DATEDIFF(MINUTE, ro.pickup_time, ot.order_time) AS time_diff
			DATEDIFF(MINUTE, ot.order_time, ro.pickup_time) AS time_diff
		FROM 
			#runner_orders AS ro
			JOIN order_time_cte AS ot ON ro.order_id = ot.order_id
		WHERE
			ro.distance != 0
	)

SELECT 
	runner_id,
	AVG(time_diff) AS avg_pickup_time
FROM 
	time_diff_cte
GROUP BY
	runner_id;

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH order_time_cte AS (
		SELECT
			order_id,
			MAX(order_time) AS order_time,
			COUNT(pizza_id) AS no_of_pizzas
		FROM
			#customer_orders
		GROUP BY
			order_id
	),
	time_diff_cte AS (
		SELECT 
			ro.order_id,
			ot.no_of_pizzas,
			ro.pickup_time,
			ot.order_time,
			-- DATEDIFF(MINUTE, ro.pickup_time, ot.order_time) AS time_diff
			DATEDIFF(MINUTE, ot.order_time, ro.pickup_time) AS time_diff
		FROM 
			#runner_orders AS ro
			JOIN order_time_cte AS ot ON ro.order_id = ot.order_id
		WHERE
			ro.distance != 0
	)

SELECT
	no_of_pizzas,
	AVG(time_diff) AS avg_time_prepare
FROM
	time_diff_cte
GROUP BY
	no_of_pizzas;

-- 4. What was the average distance travelled for each customer?
WITH cte0 AS (
		SELECT
			customer_id,
			order_id
		FROM
			#customer_orders
		GROUP BY
			customer_id,
			order_id
	)

SELECT
	cte0.customer_id,
	AVG(ro.distance) AS avg_distance
FROM
	cte0
	JOIN #runner_orders AS ro ON cte0.order_id = ro.order_id
GROUP BY
	cte0.customer_id;

-- 5. What was the difference between the longest and shortest delivery times for all orders?
WITH time_taken AS
	(
		SELECT 
			r.runner_id, 
			c.order_id, 
			c.order_time, 
			r.pickup_time, 
			DATEDIFF(MINUTE, c.order_time, r.pickup_time) AS delivery_time
		FROM 
			#customer_orders AS c
			JOIN #runner_orders AS r ON c.order_id = r.order_id
		WHERE 
			r.distance != 0
		GROUP BY 
			r.runner_id, 
			c.order_id, 
			c.order_time, 
			r.pickup_time
	)

SELECT 
	(MAX(delivery_time) - MIN(delivery_time)) AS diff_longest_shortest_delivery_time
FROM 
	time_taken
WHERE 
	delivery_time > 1;

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT 
	runner_id, 
	c.order_id, 
	COUNT(c.order_id) AS pizza_count, 
	(distance * 1000) AS distance_meter, 
	duration, 
	ROUND((distance * 1000/duration),2) AS avg_speed
FROM 
	#runner_orders AS r
	JOIN #customer_orders AS c ON r.order_id = c.order_id
WHERE 
	distance != 0
GROUP BY 
	runner_id, 
	c.order_id, 
	distance, 
	duration
ORDER BY 
	runner_id, 
	pizza_count, 
	avg_speed;

-- 7. What is the successful delivery percentage for each runner?
WITH delivery AS
(
	SELECT 
		runner_id, 
		COUNT(order_id) AS total_delivery,
		SUM(
			CASE
			WHEN distance != 0 THEN 1
			ELSE distance
			END
		) AS successful_delivery,
		SUM(
			CASE
			WHEN cancellation LIKE '%Cancel%' THEN 1 
			ELSE cancellation
			END
		) AS failed_delivery
	FROM 
		#runner_orders
	GROUP BY 
		runner_id, order_id
)

SELECT 
	runner_id, 
	(SUM(successful_delivery)/SUM(total_delivery)*100) AS successful_delivery_perc
FROM 
	delivery
GROUP BY 
	runner_id;