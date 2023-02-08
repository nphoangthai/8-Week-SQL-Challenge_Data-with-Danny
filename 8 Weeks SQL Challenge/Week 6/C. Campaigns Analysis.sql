USE CT6_Clique_Bait;
GO
SELECT
	u.user_id, e.visit_id, c.campaign_name,
	MIN(e.event_time),
	SUM(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END) AS page_views,
	SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) AS cart_adds,
	SUM(CASE WHEN e.event_type = 3 THEN 1 ELSE 0 END) AS purchases,
	SUM(CASE WHEN e.event_type = 4 THEN 1 ELSE 0 END) AS impression,
	SUM(CASE WHEN e.event_type = 5 THEN 1 ELSE 0 END) AS click,
	STRING_AGG(CASE WHEN p.product_id IS NOT NULL AND e.event_type = 2 THEN p.page_name ELSE NULL END, ',') WITHIN GROUP(ORDER BY e.sequence_number) AS cart_products
FROM 
	users AS u
	INNER JOIN events AS e
	  ON u.cookie_id = e.cookie_id
	LEFT JOIN campaign_identifier AS c
	  ON e.event_time BETWEEN c.start_date AND c.end_date
	LEFT JOIN page_hierarchy AS p
	  ON e.page_id = p.page_id
GROUP BY 
	u.user_id, e.visit_id, c.campaign_name;