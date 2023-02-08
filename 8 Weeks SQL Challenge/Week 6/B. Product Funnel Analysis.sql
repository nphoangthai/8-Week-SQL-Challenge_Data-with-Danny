USE CT6_Clique_Bait;
GO

-- Questions
-- Using a single SQL query - create a new output table which has the following details:
--		How many times was each product viewed?
--		How many times was each product added to cart?
--		How many times was each product added to a cart but not purchased (abandoned)?
--		How many times was each product purchased?
DROP TABLE IF EXISTS table1;
WITH 
product_page_events AS (
	SELECT
		a.visit_id,
		b.product_id,
		b.page_name AS product_name,
		b.product_category,
		SUM(CASE WHEN a.event_type = 1 THEN 1 ELSE 0 END) AS #views,
		SUM(CASE WHEN a.event_type = 2 THEN 1 ELSE 0 END) AS #cart_adds
	FROM
		events AS a
		JOIN page_hierarchy AS b ON a.page_id = b.page_id
	WHERE
		b.product_category IS NOT NULL
	GROUP BY
		a.visit_id, b.product_id, b.page_name, b.product_category
),
purchase_events AS (
	SELECT
		DISTINCT visit_id
	FROM
		events
	WHERE
		event_type = 3
),
combined_table AS (
	SELECT
		a.visit_id,
		a.product_id,
		a.product_name,
		a.product_category,
		a.#views,
		a.#cart_adds,
		CASE WHEN b.visit_id IS NOT NULL THEN 1 ELSE 0 END AS purchase
	FROM
		product_page_events AS a
		LEFT JOIN purchase_events AS b ON a.visit_id = b.visit_id
),
product_info AS (
	SELECT
		product_name,
		product_category,
		SUM(#views) AS #views,
		SUM(#cart_adds) AS #cart_adds,
		SUM(CASE WHEN #cart_adds = 1 AND purchase = 0 THEN 1 ELSE 0 END) AS abandoned,
		SUM(CASE WHEN #cart_adds = 1 AND purchase = 1 THEN 1 ELSE 0 END) AS purchased
	FROM
		combined_table
	GROUP BY
		product_name, product_category
)

SELECT
	*
INTO
	table1
FROM
	product_info;

-- Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.
SELECT
	product_category,
	SUM(#views) AS #views,
	SUM(#cart_adds) AS #cart_adds,
	SUM(abandoned) AS abandoned,
	SUM(purchased) AS purchased
INTO
	table2
FROM
	table1
GROUP BY
	product_category;

SELECT *
FROM table2;

-- Use your 2 new output tables - answer the following questions:

-- 1. Which product had the most views, cart adds and purchases?
-- views
SELECT
	TOP 3
	product_name,
	#views
FROM
	table1
ORDER BY
	#views DESC;

-- cart adds
SELECT
	TOP 3
	product_name,
	#cart_adds
FROM
	table1
ORDER BY
	#cart_adds DESC;

-- purchases
SELECT
	TOP 3
	product_name,
	purchased
FROM
	table1
ORDER BY
	purchased DESC;

-- 2. Which product was most likely to be abandoned?
SELECT
	TOP 3
	product_name,
	abandoned
FROM
	table1
ORDER BY
	abandoned DESC;

-- 3. Which product had the highest view to purchase percentage?
SELECT 
    product_name, 
	product_category, 
	ROUND(100 * CAST(purchased AS FLOAT)/#views,2) AS purchase_per_view_percentage
FROM table1
ORDER BY purchase_per_view_percentage DESC;

-- 4. What is the average conversion rate from view to cart add?
-- 5. What is the average conversion rate from cart add to purchase?
SELECT 
  ROUND(100*AVG(#cart_adds*1.0/#views),2) AS avg_view_to_cart_add_conversion,
  ROUND(100*AVG(purchased*1.0/#cart_adds),2) AS avg_cart_add_to_purchases_conversion_rate
FROM table1;