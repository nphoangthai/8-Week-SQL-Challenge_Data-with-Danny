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
ALTER COLUMN pickup_time DATETIME;

-- pizza_recipes Table
DROP TABLE IF EXISTS #pizza_recipes;
WITH cte AS (
	SELECT
		pizza_id,
		REPLACE(
			REPLACE(
				CONCAT('%', toppings), 
				' ', 
				'%'
			), 
			'%', 
			CONCAT(CAST(pizza_id AS nvarchar(2)), '-')
		) AS new_toppings_format
	FROM
		pizza_recipes
	)

SELECT 
	LEFT(value, CHARINDEX('-', new_toppings_format) - 1) AS pizza_id,
	RIGHT(value, LEN(value) - CHARINDEX('-', value)) AS toppings
INTO 
	#pizza_recipes
FROM 
	cte
CROSS APPLY string_split(REPLACE(new_toppings_format, ' ', ''), ',');

-- customer_order Table (For Q2, 3)
DROP TABLE IF EXISTS ##customer_orders;
WITH breakdown_extras AS 
	(
		SELECT
			co.*,
			f.value AS #extras
		FROM
			#customer_orders AS co
		CROSS APPLY string_split(REPLACE(co.extras, ' ', ''), ',') AS f
	),
	breakdown_exclusions AS
	(
		SELECT
			s.*,
			f.value AS #exclusions
		FROM
			breakdown_extras AS s
		CROSS APPLY string_split(REPLACE(s.exclusions, ' ', ''), ',') AS f
	)

SELECT
	*
INTO 
	##customer_orders
FROM 
	breakdown_exclusions;

-- ingredients list for each pizzas (For Q5, 6)
DROP TABLE IF EXISTS ingredients_list;
-- add_extra: 
	-- use pizza_recipes table to get ingredients list of each pizza id
	-- then concat extras column in #customer_orders table and ingredients list from earlier then we have add_extras column
WITH add_extra AS
	(
		SELECT
			a.order_id,
			a.pizza_id,
			a.exclusions,
			a.extras,
			b.toppings,
			CASE
				WHEN LEN(TRIM(a.extras)) != 0 THEN CONCAT(b.toppings, ', ', a.extras)
				ELSE b.toppings
				END AS add_extras
		FROM
			#customer_orders AS a
			JOIN pizza_recipes AS b ON a.pizza_id = b.pizza_id
	),
-- get_final_ingredients:
	-- use string_split to breakdown add_extras and exclusions column
	-- then select ingredients that appear in add_extras and don't in exclusions
	-- string_agg remain ingredients in add_extras columns then we have the final_ingredients used for a pizza
	get_final_ingredients AS
	(
		SELECT 
			*,
			CASE
				-- where exclusions are included
				WHEN LEN(TRIM(exclusions)) != 0 THEN 
				(
					-- string_agg remain ingredients
					SELECT
						STRING_AGG(temp0.ingredients_after_exclude, ', ') AS blah
					FROM
						(
							-- select ingredients in add_extras column and not in exclusions column (Minus two sets)
							SELECT
								a.value AS ingredients_after_exclude
							FROM string_split(REPLACE(add_extras, ' ', ''), ',') AS a
								LEFT JOIN string_split(REPLACE(exclusions, ' ', ''), ',') AS b ON a.value = b.value
							WHERE
								b.value IS NULL
						) AS temp0
				)
				ELSE add_extras
				END AS final_ingredients
		FROM
			add_extra
	)

SELECT
	*
INTO 
	ingredients_list
FROM
	get_final_ingredients;

DROP TABLE IF EXISTS pizza_price;
CREATE TABLE pizza_price (
  "pizza_id" INT,
  "price" INT
);
INSERT INTO pizza_price
  ("pizza_id", "price")
VALUES
  (1, 12),
  (2, 10);

-- Questions
-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes 
--		- how much money has Pizza Runner made so far if there are no delivery fees?
SELECT
	SUM(c.price) AS total_sales
FROM
	#runner_orders AS a
	JOIN #customer_orders AS b ON a.order_id = b.order_id
	JOIN pizza_price AS c ON b.pizza_id = c.pizza_id
WHERE
	a.distance != 0;

-- 2. What if there was an additional $1 charge for any pizza extras?
--		Ex: Add cheese is $1 extra

DROP FUNCTION IF EXISTS count_extras;
GO
CREATE FUNCTION count_extras (
	@temp VARCHAR(max)
)
RETURNS INTEGER
BEGIN
	DECLARE @return_value INTEGER
	SELECT @return_value = 
	CASE
		WHEN LEN(TRIM(@temp)) = 0 THEN 0
		ELSE
			(
				SELECT
					COUNT(*)
				FROM
					string_split(REPlACE(@temp, ' ', ''), ',') AS f
			)
		END

	RETURN @return_value
END
GO

SELECT
	SUM(price + extras_price) AS total_sales
FROM
	(
		SELECT
			c.price,
			dbo.count_extras(b.extras) AS extras_price
		FROM
			#runner_orders AS a
			JOIN #customer_orders AS b ON a.order_id = b.order_id
			JOIN pizza_price AS c ON b.pizza_id = c.pizza_id
		WHERE
			a.distance != 0
	) AS f;

-- 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, 
--		how would you design an additional table for this new dataset 
--		- generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.