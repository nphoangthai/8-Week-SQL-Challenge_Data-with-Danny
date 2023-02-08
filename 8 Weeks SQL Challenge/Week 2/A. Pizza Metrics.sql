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


-- 1. How many pizzas were ordered?
SELECT
	COUNT(*) AS total_pizzas_ordered
FROM
	#customer_orders;

-- 2. How many unique customer orders were made?
SELECT
	COUNT(DISTINCT order_id) AS unique_order
FROM
	#customer_orders;

-- 3. How many successful orders were delivered by each runner?
SELECT
	runner_id, 
	COUNT(DISTINCT order_id) AS successful_orders
FROM
	#runner_orders
WHERE
	distance <> 0
GROUP BY
	runner_id;

-- 4. How many of each type of pizza was delivered?
SELECT
	co.pizza_id,
	COUNT(*) AS total
FROM
	#runner_orders AS ro
	JOIN #customer_orders AS co ON ro.order_id = co.order_id
WHERE
	distance <> 0
GROUP BY
	co.pizza_id;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT
	pizza_names.pizza_name,
	COUNT(#customer_orders.order_id) AS counts
FROM
	#customer_orders
	JOIN pizza_names ON #customer_orders.pizza_id = pizza_names.pizza_id
GROUP BY
	pizza_names.pizza_name;

-- 6. What was the maximum number of pizzas delivered in a single order?
WITH cte AS (
	SELECT
		co.order_id,
		COUNT(pizza_id) AS pizzas_per_order
	FROM
		#customer_orders AS co
		JOIN #runner_orders AS ro ON co.order_id = ro.order_id
	WHERE
		ro.distance != 0
	GROUP BY
		co.order_id
)	

SELECT 
	MAX(pizzas_per_order) AS max_pizzas
FROM 
	cte;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT
	co.customer_id,
	SUM(
		CASE
			WHEN co.extras != ' ' AND co.exclusions != ' ' THEN 1
			ELSE 0
			END
	) AS no_changes,
	SUM(
		CASE
			WHEN co.extras != ' ' OR co.exclusions != ' ' THEN 1
			ELSE 0
			END
	) AS with_changes
FROM
	#customer_orders AS co
	JOIN #runner_orders AS ro ON co.order_id = ro.order_id
WHERE
	ro.distance != 0
GROUP BY
	co.customer_id
ORDER BY
	co.customer_id;

-- 8. How many pizzas were delivered that had both exclusions and extras?
SELECT
	SUM(
		CASE
			WHEN co.exclusions != ' ' AND co.extras != ' ' THEN 1
			ELSE 0
			END
	) AS both_changes
FROM
	#customer_orders AS co
	JOIN #runner_orders AS ro ON co.order_id = ro.order_id
WHERE
	ro.distance != 0

-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT 
	DATEPART(HOUR, [order_time]) AS hour_of_the_day,
	COUNT(order_id) AS total_pizzas_ordered
FROM 
	#customer_orders
GROUP BY 
	DATEPART(HOUR, [order_time])

-- 10. What was the volume of orders for each day of the week?
SELECT 
	DATEPART(DAY, [order_time]) AS day_of_week,
	COUNT(order_id) AS total_pizzas_ordered
FROM 
	#customer_orders
GROUP BY 
	DATEPART(DAY, [order_time])