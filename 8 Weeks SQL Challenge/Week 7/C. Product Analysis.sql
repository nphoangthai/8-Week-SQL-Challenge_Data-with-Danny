USE CT7_Balanced_Tree_Clothing_Co;
GO
 
-- 1. What are the top 3 products by total revenue before discount?
SELECT
	TOP 3
	b.product_name,
	SUM(a.qty*a.price) AS revenue
FROM
	sales AS a
	JOIN product_details AS b ON a.prod_id = b.product_id
GROUP BY
	b.product_name
ORDER BY
	revenue DESC;

-- 2. What is the total quantity, revenue and discount for each segment?
SELECT
	c.level_text AS segment,
	SUM(a.qty) AS quantity,
	ROUND(SUM(CAST(a.qty*a.price*(100 - a.discount) AS FLOAT)/100), 2) AS revenue,
	ROUND(SUM(CAST(a.qty*a.price*a.discount AS FLOAT)/100), 2) AS discount
FROM
	sales AS a
	JOIN product_details AS b ON a.prod_id = b.product_id
	JOIN product_hierarchy AS c ON b.segment_id = c.id
GROUP BY
	c.level_text;

-- 3. What is the top selling product for each segment?
WITH 
cte0 AS (
	SELECT
		b.segment_name AS segment, b.product_name,
		SUM(a.qty) AS quantity
	FROM
		sales AS a
		JOIN product_details AS b ON a.prod_id = b.product_id
	GROUP BY
		b.segment_name, b.product_name
),
cte1 AS (
	SELECT
		segment,
		MAX(quantity) AS max_quantity
	FROM
		cte0
	GROUP BY
		segment
)

SELECT
	a.segment,
	a.product_name,
	a.quantity
FROM
	cte0 AS a
	JOIN cte1 AS b ON (a.segment = b.segment AND a.quantity = b.max_quantity);

-- 4. What is the total quantity, revenue and discount for each category?
SELECT
	b.category_name,
	SUM(a.qty) AS quantity,
	ROUND(SUM(CAST(a.qty*a.price*(100 - a.discount) AS FLOAT)/100), 2) AS revenue,
	ROUND(SUM(CAST(a.qty*a.price*a.discount AS FLOAT)/100), 2) AS discount
FROM
	sales AS a
	JOIN product_details AS b ON a.prod_id = b.product_id
GROUP BY
	b.category_name;

-- 5. What is the top selling product for each category?
WITH 
cte0 AS (
	SELECT
		b.category_name AS category, b.product_name,
		SUM(a.qty) AS quantity
	FROM
		sales AS a
		JOIN product_details AS b ON a.prod_id = b.product_id
	GROUP BY
		b.category_name, b.product_name
),
cte1 AS (
	SELECT
		category,
		MAX(quantity) AS max_quantity
	FROM
		cte0
	GROUP BY
		category
)

SELECT
	a.category,
	a.product_name,
	a.quantity
FROM
	cte0 AS a
	JOIN cte1 AS b ON (a.category = b.category AND a.quantity = b.max_quantity);

-- 6. What is the percentage split of revenue by product for each segment?
SELECT
	b.segment_name,
	ROUND(SUM(CAST(a.qty*a.price*(100 - a.discount)/100 AS FLOAT)), 2) AS revenue,
	ROUND(SUM(CAST(a.qty*a.price*(100 - a.discount)/100 AS FLOAT))*100 / (SELECT SUM(qty*price*(100 - discount)/100) FROM sales), 2) AS percentage
FROM
	sales AS a
	JOIN product_details AS b ON a.prod_id = b.product_id
GROUP BY
	b.segment_name
ORDER BY
	revenue DESC;

-- 7. What is the percentage split of revenue by segment for each category?
WITH
cte0 AS (
	SELECT
		b.category_name AS category, b.segment_name AS segment,
		ROUND(SUM(CAST(a.qty*a.price*(100 - a.discount)/100 AS FLOAT)), 2) AS revenue
		-- ROUND(SUM(CAST(a.qty*a.price*(100 - a.discount)/100 AS FLOAT))*100 / (SELECT SUM(qty*price*(100 - discount)/100) FROM sales), 2) AS percentage
	FROM
		sales AS a
		JOIN product_details AS b ON a.prod_id = b.product_id
	GROUP BY
		b.category_name, b.segment_name
),
cte1 AS (
	SELECT
		category, 
		SUM(revenue) AS total_revenue_per_category
	FROM
		cte0
	GROUP BY
		category
)

SELECT
	a.category,
	a.segment,
	a.revenue,
	ROUND(100*CAST(a.revenue AS FLOAT)/b.total_revenue_per_category, 2) AS percentage
FROM
	cte0 AS a 
	JOIN cte1 AS b ON a.category = b.category
ORDER BY
	category ASC, percentage DESC;

-- 8. What is the percentage split of total revenue by category?
SELECT
	b.category_name AS category,
	ROUND(SUM(CAST(a.qty*a.price*(100 - a.discount)/100 AS FLOAT)), 2) AS revenue,
	ROUND(SUM(CAST(a.qty*a.price*(100 - a.discount)/100 AS FLOAT))*100 / (SELECT SUM(qty*price*(100 - discount)/100) FROM sales), 2) AS percentage
FROM
	sales AS a
	JOIN product_details AS b ON a.prod_id = b.product_id
GROUP BY
	b.category_name;

-- 9. What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
WITH
cte0 AS (
	SELECT
		a.txn_id, b.product_name,
		SUM(CASE WHEN a.qty = 1 THEN 1 ELSE 0 END) AS penetration
	FROM
		sales AS a
		JOIN product_details AS b ON a.prod_id = b.product_id
	GROUP BY
		a.txn_id, b.product_name
	HAVING 
		SUM(CASE WHEN a.qty = 1 THEN 1 ELSE 0 END) >= 1
)

SELECT
	product_name, 
	COUNT(DISTINCT txn_id) AS #transactions
FROM
	cte0
GROUP BY
	product_name
ORDER BY
	#transactions DESC;

-- 10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?