-- 1. What is the total amount each customer spent at the restaurant?

SELECT 
	s.customer_id
	, SUM(m.price) as total_amount
FROM dbo.sales as s
JOIN dbo.menu as m
ON s.product_id=m.product_id
GROUP BY s.customer_id;

 -- 2. How many days has each customer visited the restaurant?

SELECT 
	customer_id
	, COUNT(DISTINCT(order_date)) as total_days
FROM dbo.sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?

SELECT 
	DISTINCT s.customer_id
	, s.order_date
	, m.product_name as first_item
FROM dbo.sales as s 
JOIN dbo.menu as m
ON s.product_id=m.product_id
WHERE s.order_date = (SELECT min(order_date)
					  FROM dbo.sales);

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT 
	top 1 count(s.product_id) as amount_of_product
	, m.product_name
FROM dbo.sales as s 
JOIN dbo.menu as m
ON s.product_id=m.product_id
GROUP BY s.product_id, m.product_name
ORDER BY count(s.product_id) desc;

-- 5. Which item was the most popular for each customer? 

SELECT 
	customer_id
	, product_name
	, quantity
FROM 
		(SELECT 
			s.customer_id
			, m.product_name
			, COUNT(m.product_name) as quantity
			, DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(m.product_name) desc) as r 
		FROM dbo.sales as s 
		JOIN dbo.menu as m 
		ON s.product_id=m.product_id
		GROUP BY s.customer_id, m.product_name)  AS sub

WHERE r = 1
ORDER BY customer_id;

-- 6. Which item was purchased just before the customer became a member?

SELECT 
	customer_id
	, product_name
	, join_date
	, order_date
FROM
		(SELECT 
			mem.customer_id
			, m.product_name
			, mem.join_date
			, min(s.order_date) as order_date
			, DENSE_RANK() OVER (PARTITION BY mem.customer_id ORDER BY min(s.order_date)) as r
		FROM dbo.sales as s 
		JOIN dbo.menu as m 
		ON s.product_id=m.product_id
			JOIN members as mem
			ON s.customer_id=mem.customer_id
		WHERE s.order_date >= mem.join_date
		GROUP BY mem.customer_id, mem.join_date, m.product_name) as sub

WHERE r = 1;

-- 7. What is the total items and amount spent for each member before they became a member?

SELECT 
	s.customer_id
	, count(s.product_id) as SalesCount
	, sum(m.price) as TotalAmount
FROM dbo.sales as s 
JOIN dbo.menu as m 
ON s.product_id = m.product_id
	JOIN members as mem
	ON s.customer_id = mem.customer_id
WHERE s.order_date < mem.join_date
GROUP BY s.customer_id;

-- 8. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT 
	s.customer_id
	, sum(
			CASE 
			when m.product_name = 'sushi' then m.price * 20
			else m. price * 10 
			end) as points
FROM dbo.sales as s 
JOIN dbo.menu as m 
ON s.product_id = m.product_id
GROUP BY s.customer_id;

-- 9. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT s.customer_id
		, sum(
				CASE 
				when m.product_name = 'sushi' then m.price * 20
				when s.order_date between mem.join_date and dateadd(day, 7, join_date) then m.price * 20
				else m. price * 10 
				end) as points
FROM dbo.sales as s 
JOIN dbo.menu as m 
ON s.product_id = m.product_id
	JOIN members as mem
	ON s.customer_id = mem.customer_id
WHERE s.order_date < '20210201'
GROUP BY s.customer_id;


-- Bonus Questions - Join All The Things

SELECT s.customer_id
	, s.order_date
	, m.product_name
	, m.price
	, CASE 
	when s.order_date >= mem.join_date then 'Y'
	else 'N'
	END as member
FROM dbo.sales as s 
FULL JOIN dbo.menu as m 
ON s.product_id=m.product_id
	FULL JOIN members as mem
	ON s.customer_id=mem.customer_id
ORDER BY s.customer_id, s.order_date;

-- Bonus Questions - Rank All The Things

SELECT customer_id
	, order_date
	, product_name
	, price
	, member
	, CASE 
	when member = 'N' then null
	else DENSE_RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date) end as Ranking
FROM 
			(SELECT s.customer_id
				, s.order_date
				, m.product_name
				, m.price
				, CASE 
				when s.order_date >= mem.join_date then 'Y'
				else 'N'
				END as member
			FROM dbo.sales as s 
			FULL JOIN dbo.menu as m 
			ON s.product_id=m.product_id
				FULL JOIN members as mem
				ON s.customer_id=mem.customer_id
			) as sub

ORDER BY customer_id, order_date;