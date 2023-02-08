-- Use Database
USE CT4_Data_Bank;
GO

-- Questions
-- 1. How many unique nodes are there on the Data Bank system?
SELECT
	COUNT(DISTINCT node_id) AS #nodes
FROM
	customer_nodes;

-- 2. What is the number of nodes per region?
SELECT
	b.region_name,
	COUNT(a.node_id) AS #nodes
FROM
	customer_nodes AS a
	JOIN regions AS b ON a.region_id = b.region_id
GROUP BY
	b.region_name;

-- 3. How many customers are allocated to each region?
SELECT
	b.region_name,
	COUNT(a.customer_id) AS #customers
FROM
	customer_nodes AS a
	JOIN regions AS b ON a.region_id = b.region_id
GROUP BY
	b.region_name;

-- 4. How many days on average are customers reallocated to a different node?
WITH node_diff AS (
		SELECT
			customer_id, node_id, start_date, end_date,
			DATEDIFF(DAY, start_date, end_date) AS diff
		FROM
			customer_nodes
		WHERE
			end_date != '9999-12-31'
		GROUP BY
			customer_id, node_id, start_date, end_date
	),
	sum_diff_cte AS (
		SELECT
			customer_id, node_id, 
			SUM(diff) AS sum_diff
		FROM
			node_diff
		GROUP BY
			customer_id, node_id
	)

SELECT
	ROUND(AVG(sum_diff), 2) AS avg_reallocation_days
FROM
	sum_diff_cte;

-- 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
