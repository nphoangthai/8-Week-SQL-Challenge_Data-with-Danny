USE CT1_Danny_Diner

GO

-- Case study questions

-- 1. What is the total amount each customer spent at the restaurant?
SELECT
	sales.customer_id,
	SUM(menu.price) AS total_money_paid
FROM sales
	JOIN menu ON sales.product_id = menu.product_id
GROUP BY
	sales.customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT
	customer_id,
	COUNT(DISTINCT order_date) AS visits
FROM
	sales
GROUP BY
	customer_id;

-- 3. What was the first item from the menu purchased by each customer?
WITH ordered_sales_cte AS
(
	SELECT 
		customer_id, 
		order_date, 
		product_name,
		DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rank
	FROM sales AS s
		JOIN menu AS m ON s.product_id = m.product_id
)

SELECT 
  customer_id, 
  product_name
FROM ordered_sales_cte
WHERE rank = 1
GROUP BY customer_id, product_name;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
WITH item_counts AS (
		SELECT
			product_id,
			COUNT(product_id) AS counts
		FROM 
			sales
		GROUP BY
			product_id
	)

SELECT 
	menu.product_name AS most_purchased_item,
	item_counts.counts
FROM 
	item_counts 
	JOIN menu ON item_counts.product_id = menu.product_id 
WHERE 
	item_counts.counts = (SELECT MAX(item_counts.counts) FROM item_counts);

-- 5. Which item was the most popular for each customer?
WITH item_count_by_customer AS (
		SELECT
			customer_id,
			product_id,
			COUNT(product_id) AS counts,
			DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(product_id) DESC) AS rank_
		FROM
			sales
		GROUP BY
			customer_id,
			product_id
	)
SELECT
	item_count_by_customer.customer_id,
	menu.product_name,
	item_count_by_customer.counts
FROM 
	item_count_by_customer
	JOIN menu ON item_count_by_customer.product_id = menu.product_id
WHERE item_count_by_customer.rank_ = 1;

-- 6. Which item was purchased first by the customer after they became a member?
WITH cte AS (
		SELECT
			sales.customer_id,
			sales.product_id,
			sales.order_date,
			members.join_date,
			DENSE_RANK() OVER(PARTITION BY sales.customer_id ORDER BY sales.order_date) AS rank_
		FROM
			sales
			JOIN members ON sales.customer_id = members.customer_id
		WHERE	
			sales.order_date >= members.join_date
	)
	
SELECT
	cte.customer_id,
	menu.product_name,
	cte.order_date,
	cte.join_date
FROM
	cte
	JOIN menu ON cte.product_id = menu.product_id
WHERE cte.rank_ = 1;

-- 7. Which item was purchased just before the customer became a member?
WITH cte AS (
		SELECT
			sales.customer_id,
			sales.product_id,
			sales.order_date,
			members.join_date,
			DENSE_RANK() OVER(PARTITION BY sales.customer_id ORDER BY sales.order_date DESC) AS rank_
		FROM
			sales
			JOIN members ON sales.customer_id = members.customer_id
		WHERE	
			sales.order_date < members.join_date
	)
	
SELECT
	cte.customer_id,
	menu.product_name,
	cte.order_date,
	cte.join_date
FROM
	cte
	JOIN menu ON cte.product_id = menu.product_id
WHERE cte.rank_ = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
WITH before_member AS (
		SELECT
			sales.customer_id,
			sales.order_date,
			sales.product_id,
			members.join_date
		FROM
			sales
			JOIN members ON sales.customer_id = members.customer_id
		WHERE sales.order_date < members.join_date
	)

SELECT
	before_member.customer_id,
	COUNT(before_member.product_id) AS product_counts,
	SUM(menu.price) AS total_sales
FROM
	before_member
	JOIN menu ON before_member.product_id = menu.product_id
GROUP BY
	before_member.customer_id;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
DECLARE @points_by_1d AS INT = 10;

WITH cte AS (
		SELECT 
			sales.customer_id,
			CASE
				WHEN menu.product_name = 'sushi' THEN 2*menu.price*@points_by_1d
				ELSE menu.price*@points_by_1d
				END AS point
		FROM
			sales
			JOIN menu ON sales.product_id = menu.product_id
	)

SELECT 
	customer_id,
	SUM(point) AS total_points
FROM
	cte
GROUP BY customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH valid_date_cte AS (
		SELECT
			sales.customer_id,
			sales.order_date,
			sales.product_id,
			members.join_date,
			DATEADD(DAY, 6, members.join_date) AS valid_date,
			EOMONTH('2021-01-31') AS last_date
		FROM
			sales
			JOIN members ON sales.customer_id = members.customer_id
	),
	assign_point_cte AS (
		SELECT
			valid_date_cte.customer_id,
			valid_date_cte.product_id,
			CASE
				WHEN menu.product_name = 'sushi' THEN 2*10*menu.price
				WHEN valid_date_cte.order_date BETWEEN valid_date_cte.join_date AND valid_date_cte.valid_date THEN 2*10*menu.price
				ELSE 10*menu.price
				END AS points
		FROM
			valid_date_cte
			JOIN menu ON valid_date_cte.product_id = menu.product_id
		WHERE
			valid_date_cte.order_date < = valid_date_cte.last_date
	)

SELECT
	customer_id,
	SUM(points) AS total_points
FROM
	assign_point_cte
GROUP BY
	customer_id;
