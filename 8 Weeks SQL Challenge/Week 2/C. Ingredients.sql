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

-- Questions
-- 1. What are the standard ingredients for each pizza?
SELECT
	pr.pizza_id,
	pn.pizza_name,
	STRING_AGG(pt.topping_name, ', ') AS ingredients
FROM
	#pizza_recipes AS pr
	JOIN pizza_toppings AS pt ON pr.toppings = pt.topping_id
	JOIN pizza_names AS pn ON pr.pizza_id = pn.pizza_id
GROUP BY
	pr.pizza_id,
	pn.pizza_name;

-- 2. What was the most commonly added extra?
SELECT
	TOP 1
	##co.#extras,
	pt.topping_name,
	COUNT(##co.#extras) AS counts
FROM
	##customer_orders AS ##co
	JOIN pizza_toppings AS pt ON ##co.#extras = pt.topping_id
GROUP BY
	##co.#extras,
	pt.topping_name
ORDER BY
	COUNT(##co.#extras) DESC

-- 3. What was the most common exclusion?
SELECT
	TOP 1
	##co.#exclusions,
	pt.topping_name,
	COUNT(##co.#exclusions) AS counts
FROM
	##customer_orders AS ##co
	JOIN pizza_toppings AS pt ON ##co.#exclusions = pt.topping_id
GROUP BY
	##co.#exclusions,
	pt.topping_name
ORDER BY
	COUNT(##co.#exclusions) DESC;

-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
--		Meat Lovers
--		Meat Lovers - Exclude Beef
--		Meat Lovers - Extra Bacon
--		Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
-- Keywords: string_agg distinct values
WITH add_name AS 
	(
		SELECT
			a.order_id,
			a.customer_id,
			d.pizza_name,
			b.topping_name AS extras_topping_name,
			c.topping_name AS exclu_topping_name,
			a.extras,
			a.exclusions
		FROM
			##customer_orders AS a
			LEFT JOIN pizza_toppings AS b ON a.#extras = b.topping_id
			LEFT JOIN pizza_toppings AS c ON a.#exclusions = c.topping_id
			LEFT JOIN pizza_names AS d ON a.pizza_id = d.pizza_id
	),
	agg_extra_exclu AS
	(
		SELECT
		temp.order_id,
		temp.customer_id,
		temp.pizza_name,
		CASE
			WHEN temp.#extras IS NOT NULL THEN CONCAT(' - Include ', temp.#extras)
			ELSE ''
			END AS #extras,
		CASE
			WHEN temp.#exclus IS NOT NULL THEN CONCAT(' - Exclude ', temp.#exclus)
			ELSE ''
			END AS #exclus
		FROM
			(
				SELECT
					a.order_id,
					a.customer_id,
					a.pizza_name,
					a.extras,
					a.exclusions,
					(select string_agg(value, ', ') from (select distinct value from string_split(string_agg(a.extras_topping_name, ','),',')) t) AS #extras,
					(select string_agg(value, ', ') from (select distinct value from string_split(string_agg(a.exclu_topping_name, ','),',')) t) AS #exclus
				FROM
					add_name AS a
				GROUP BY
					a.order_id,
					a.customer_id,
					a.pizza_name,
					a.extras,
					a.exclusions
			) AS temp
	)

SELECT
	a.order_id,
	a.customer_id,
	CONCAT(a.pizza_name, a.#extras, a.#exclus) AS order_item
FROM
	agg_extra_exclu AS a;

-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
--		For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
-- Keywords: User-defined function
DROP FUNCTION IF EXISTS C_Q5;
GO
CREATE FUNCTION C_Q5 (
	@temp VARCHAR(max)
)
RETURNS VARCHAR(max)
BEGIN
	DECLARE @return_value VARCHAR(max)
	SELECT @return_value = 
	(
		SELECT
			STRING_AGG(#topping_name, ', ') WITHIN GROUP (ORDER BY #topping_name)
		FROM
			(
				SELECT
					CASE 
						WHEN counts > 1 THEN CONCAT(CAST(counts AS VARCHAR(max)), 'x', topping_name)
						ELSE topping_name
						END AS #topping_name
				FROM
					(
						SELECT
						f.value,
						b.topping_name,
						COUNT(*) AS counts
						FROM
							string_split(REPLACE(@temp, ' ', ''), ',') AS f
							JOIN pizza_toppings AS b ON f.value = b.topping_id
						GROUP BY
							f.value,
							b.topping_name
					) AS temp0
			) AS temp1	
	)

	RETURN @return_value
END
GO

SELECT
	a.order_id,
	CONCAT(b.pizza_name, ': ', dbo.blahblah(a.final_ingredients)) AS #ingredients_list
FROM
	ingredients_list AS a
	JOIN pizza_names AS b ON a.pizza_id = b.pizza_id;



	

-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
SELECT
	b.topping_name,
	a.counts
FROM
	(
		SELECT
			f.value,
			COUNT(*) AS counts
		FROM 
			string_split(
				REPLACE((SELECT STRING_AGG(final_ingredients, ', ') FROM ingredients_list), ' ', ''), ','
			) AS f
		GROUP BY
			f.value
	) AS a
	JOIN pizza_toppings AS b ON a.value = b.topping_id
ORDER BY
	a.counts DESC;