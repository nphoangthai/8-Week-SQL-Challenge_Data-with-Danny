USE CT6_Clique_Bait;
GO

-- Questions
-- 1. How many users are there?
SELECT
	COUNT(DISTINCT user_id) AS #unique_users
FROM
	users;

-- 2. How many cookies does each user have on average?
WITH cte AS (
	SELECT
  		user_id,
  		COUNT(cookie_id) AS total_cookies
  	FROM
  		users
 	GROUP BY
  		user_id
)

SELECT
	ROUND(AVG(total_cookies), 0) AS avg_cookies
FROM
	cte;

-- 3. What is the unique number of visits by all users per month?
SELECT
	MONTH(event_time) AS month,
    COUNT(DISTINCT visit_id) AS #unique_visits
FROM
	events
GROUP BY
	MONTH(event_time)
ORDER BY
	month;

-- 4. What is the number of events for each event type?
SELECT
	b.event_name,
	COUNT(*) AS #events,
	ROUND(100 * CAST(COUNT(*) AS FLOAT)/(SELECT COUNT(*) FROM events), 2) AS percentage
FROM
	events AS a
	JOIN event_identifier AS b ON a.event_type = b.event_type
GROUP BY
	b.event_name
ORDER BY
	#events DESC;

-- 5. What is the percentage of visits which have a purchase event?
SELECT
	ROUND(100 * CAST(COUNT(DISTINCT visit_id) AS FLOAT) / (SELECT COUNT(DISTINCT visit_id) FROM events), 2) AS percentage_purchase
FROM
	events AS a
	JOIN event_identifier AS b ON a.event_type = b.event_type
WHERE
	b.event_name = 'Purchase' ;

-- 6. What is the percentage of visits which view the checkout page but do not have a purchase event?
WITH
-- visits which view the checkout page
cte1 AS (
	SELECT
		DISTINCT visit_id
	FROM
		events
	WHERE
		event_type = 1		-- Page View
		AND page_id = 12	-- Checkout
),
-- visits which have a purchase event
cte2 AS (
	SELECT
		visit_id
	FROM
		events
	WHERE
		event_type = 3		-- Purchase
),
-- select visit_id that appear in cte1 and not in cte2
cte3 AS (
	SELECT
		cte1.visit_id AS Q,
		cte2.visit_id
	FROM
		cte1 
		LEFT JOIN cte2 ON cte1.visit_id = cte2.visit_id
	WHERE
		cte2.visit_id IS NULL
)

SELECT
	ROUND(100 * (CAST(COUNT(*) AS FLOAT) / (SELECT COUNT(DISTINCT visit_id) FROM events)), 2) AS percentage_view_checkout
FROM
	cte3;

-- 7. What are the top 3 pages by number of views?
SELECT
	TOP 3
	b.page_name,
	COUNT(*) AS counts
FROM
	events AS a
	JOIN page_hierarchy AS b ON a.page_id = b.page_id
WHERE
	a.event_type = 1		-- Page View
GROUP BY
	b.page_name
ORDER BY
	counts DESC;

-- 8. What is the number of views and cart adds for each product category?
SELECT
	b.product_category,
	SUM(CASE WHEN a.event_type = 1 THEN 1 ELSE 0 END) AS views,
	SUM(CASE WHEN a.event_type = 2 THEN 1 ELSE 0 END) AS cart_adds
FROM
	events AS a
	JOIN page_hierarchy AS b ON a.page_id = b.page_id
WHERE
	b.product_category IS NOT NULL
GROUP BY
	b.product_category;

-- 9. What are the top 3 products by purchases?
SELECT
	TOP 3
	b.page_name,
	COUNT(*) AS purchases
FROM
	events AS a
	JOIN page_hierarchy AS b ON a.page_id = b.page_id
WHERE
	-- select visit_ids that made a purchase
	a.visit_id IN (SELECT DISTINCT visit_id FROM events WHERE event_type = 3)
	AND a.event_type = 2
GROUP BY
	b.page_name
ORDER BY
	purchases DESC;
