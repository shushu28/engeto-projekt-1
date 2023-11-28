-- research question no. 2

CREATE VIEW t_jana_holcman_otazka_2 AS
	WITH salary AS
	(
		SELECT primary_table.name AS name,
			   primary_table.value AS salary,
			   primary_table.year_c AS year_c 
		FROM t_jana_holcman_project_sql_primary_final AS primary_table 
		WHERE type = 'salary' 
		  AND name IS NOT NULL
	),
	product AS 
	(
		SELECT primary_table.name AS product, 
			   primary_table.value AS price, 
			   primary_table.price_value AS price_value, 
			   primary_table.unit AS unit, 
			   primary_table.year_c AS year_p 
		FROM t_jana_holcman_project_sql_primary_final AS primary_table 
		WHERE type = 'product' 
		  AND (name = 'Chléb konzumní kmínový' OR name = 'Mléko polotučné pasterované')
	), 
	salary_product AS 
	(
		SELECT * FROM salary
		INNER JOIN product ON salary.year_c = product.year_p
	), 
	salary_product_final AS 
	(
		SELECT ROUND(avg(salary), 2) AS salary, 
			   ROUND(avg(price), 2) AS price, 
			   ROUND(avg(salary) / AVG(price), 0) AS quantity, 
			   year_c, 
			   product 
		FROM salary_product
		GROUP BY year_c, 
				 product
	), 
	salary_product_min AS
	(
		SELECT * FROM salary_product_final ORDER BY year_c ASC LIMIT 2
	), 
	salary_product_max AS
	(
		SELECT * FROM salary_product_final ORDER BY year_c DESC LIMIT 2
	)
	SELECT * FROM salary_product_min 
	UNION ALL 
	SELECT * FROM salary_product_max ORDER BY product ASC, year_c ASC;
