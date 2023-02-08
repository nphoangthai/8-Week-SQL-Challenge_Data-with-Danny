USE CT3_Foodie_Fi
GO

-- Questions
-- 1. How many customers has Foodie-Fi ever had?
SELECT
	COUNT(DISTINCT customer_id) AS total_customers
FROM
	subscriptions;

-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT
	DATEPART(MONTH, a.start_date) AS #month,
	COUNT(DISTINCT a.customer_id) AS no_customers
FROM
	subscriptions AS a
	JOIN plans AS b ON a.plan_id = b.plan_id
WHERE 
	b.plan_id = 0
GROUP BY
	DATEPART(MONTH, a.start_date)
ORDER BY
	DATEPART(MONTH, a.start_date);

-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT
	b.plan_name AS #plan,
	COUNT(*) AS no_events
FROM
	subscriptions AS a
	JOIN plans AS b ON a.plan_id = b.plan_id
WHERE
	DATEPART(YEAR, a.start_date) > 2020
GROUP BY
	b.plan_name
ORDER BY
	COUNT(*) DESC;

-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT
	COUNT(DISTINCT a.customer_id) AS total_customers,
	ROUND(
		(CAST(COUNT(DISTINCT a.customer_id) AS FLOAT)/CAST((SELECT COUNT(DISTINCT customer_id) FROM subscriptions) AS FLOAT))*100, 2) AS percen
FROM
	subscriptions AS a
WHERE
	a.plan_id = 4;

-- 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
DECLARE @temp AS INTEGER;
SELECT @temp = COUNT(DISTINCT customer_id) FROM subscriptions;

WITH cte1 AS  (
	SELECT
		*,
		DENSE_RANK() OVER(PARTITION BY a.customer_id ORDER BY a.start_date) AS #rank_of_plans_by_date
	FROM
		subscriptions AS a
),
	cte2 AS (
	SELECT
		customer_id
	FROM
		cte1
	WHERE
		plan_id = 0 AND #rank_of_plans_by_date = 1
		OR
		plan_id = 4 AND #rank_of_plans_by_date = 2
	GROUP BY
		customer_id
	HAVING
		COUNT(DISTINCT plan_id) = 2
)

SELECT
	COUNT(DISTINCT customer_id) AS total,
	100*CAST(COUNT(DISTINCT customer_id) AS FLOAT)/CAST(@temp AS FLOAT) AS percen
FROM
	cte2;

-- 6. What is the number and percentage of customer plans after their initial free trial?
SELECT
	b.plan_name,
	COUNT(DISTINCT a.customer_id) AS customer_count,
	ROUND(100*CAST(COUNT(DISTINCT a.customer_id) AS FLOAT)/CAST((SELECT COUNT(DISTINCT customer_id) FROM subscriptions) AS FLOAT), 2) AS percen
FROM
	subscriptions AS a
	JOIN plans AS b ON a.plan_id = b.plan_id
WHERE
	a.plan_id != 0
GROUP BY
	b.plan_name;

-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
--SELECT
--	b.plan_name,
--	COUNT(DISTINCT a.customer_id) AS customer_count,
--	ROUND(100*CAST(COUNT(DISTINCT a.customer_id) AS FLOAT)/CAST((SELECT COUNT(DISTINCT customer_id) FROM subscriptions) AS FLOAT), 2) AS percen
--FROM
--	subscriptions AS a
--	JOIN plans AS b ON a.plan_id = b.plan_id
--WHERE
--	a.start_date <= '2020-12-31'
--GROUP BY
--	b.plan_name

-- 8. How many customers have upgraded to an annual plan in 2020?
SELECT
	COUNT(DISTINCT a.customer_id) AS total_customers
FROM
	subscriptions AS a
WHERE
	YEAR(a.start_date) = 2020
	AND
	a.plan_id = 3;

-- 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
WITH trial_plan_customer_cte AS
	(
		SELECT
			a.customer_id,
			a.plan_id,
			a.start_date,
			b.plan_name
		FROM
			subscriptions AS a
			JOIN plans AS b ON a.plan_id = b.plan_id
		WHERE 
			a.plan_id = 0
	),
	annual_plan_customer_cte AS
	(
		SELECT
			a.customer_id,
			a.plan_id,
			a.start_date,
			b.plan_name
		FROM
			subscriptions AS a
			JOIN plans AS b ON a.plan_id = b.plan_id
		WHERE 
			a.plan_id = 3
	)

SELECT
	ROUND(
		CAST(AVG(DATEDIFF(DAY, a.start_date, b.start_date)) AS FLOAT),
		2
	) AS avg_conversion_days
FROM
	trial_plan_customer_cte AS a
	INNER JOIN annual_plan_customer_cte AS b ON a.customer_id = b.customer_id;

-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)


-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?