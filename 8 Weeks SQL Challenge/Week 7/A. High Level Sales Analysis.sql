USE CT7_Balanced_Tree_Clothing_Co;
GO

-- Questions
-- 1. What was the total quantity sold for all products?
SELECT
	b.product_name,
	SUM(a.qty) AS quantity
FROM
	sales AS a
	JOIN product_details AS b ON a.prod_id = b.product_id
GROUP BY
	b.product_name
ORDER BY
	quantity DESC;

-- 2. What is the total generated revenue for all products before discounts?
SELECT
	b.product_name,
	SUM(a.price*a.qty) AS revenue
FROM
	sales AS a
	JOIN product_details AS b ON a.prod_id = b.product_id
GROUP BY
	b.product_name
ORDER BY
	revenue DESC;

-- 3. What was the total discount amount for all products?
SELECT
	b.product_name,
	SUM(a.qty*a.price*a.discount/100) AS total_discounts
FROM
	sales AS a
	JOIN product_details AS b ON a.prod_id = b.product_id
GROUP BY
	b.product_name
ORDER BY
	total_discounts DESC;