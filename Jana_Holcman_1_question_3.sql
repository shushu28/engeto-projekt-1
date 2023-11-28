-- úkol č. 3

CREATE VIEW t_jana_holcman_otazka_3 AS
	WITH product AS
	(
		SELECT primary_table.*, 
			   IF((primary_table.name <> LAG(primary_table.name) OVER (ORDER BY primary_table.name ASC, primary_table.year_c ASC) or LAG(primary_table.name) OVER (ORDER BY primary_table.name ASC, primary_table.year_c ASC) IS NULL), 
			     0,
			     ROUND((primary_table.value / (LAG(primary_table.value) OVER (ORDER BY primary_table.name ASC, primary_table.year_c ASC)) * 100) - 100, 0)) AS increase_p
		FROM t_jana_holcman_project_sql_primary_final AS primary_table
		WHERE type = 'product'
		ORDER BY name ASC, 
				 year_c ASC
	), 
	product_final AS
	(
		SELECT name, ROUND(sum(increase_p), 0) AS grow 
		FROM product
		GROUP BY name 
	)
	SELECT * FROM product_final ORDER BY grow ASC;
