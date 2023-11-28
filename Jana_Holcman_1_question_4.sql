-- research question no. 4

CREATE VIEW t_jana_holcman_otazka_4 AS
	WITH salary AS
	(
		SELECT primary_table.year_c AS year_s,
			   ROUND(avg(primary_table.value), 0) AS value_s 
		FROM t_jana_holcman_project_sql_primary_final AS primary_table 
		WHERE primary_table.type = 'salary' 
		  AND primary_table.name IS NOT NULL
		GROUP BY primary_table.year_c
	), 
	product AS
	(
		SELECT primary_table.year_c AS year_p,
			   ROUND(avg(primary_table.value), 0) AS value_p 
		FROM t_jana_holcman_project_sql_primary_final primary_table 
		WHERE primary_table.type = 'product' 
		  AND primary_table.name IS NOT NULL
		GROUP BY primary_table.year_c
	), 
	salary_product AS 
	(
		SELECT * FROM salary 
		INNER JOIN product ON salary.year_s = product.year_p
	), 
	salary_product_final AS 
	(
		SELECT year_s,
			   value_s,
			   IF((LAG(year_s) OVER (ORDER BY year_s ASC) IS NULL), 
			     0,
			     ROUND((value_s / (LAG(value_s) OVER (ORDER BY year_s ASC)) * 100) - 100, 0)) AS salary_p,
			   value_p,
			   IF((LAG(year_s) OVER (ORDER BY year_s ASC) IS NULL), 
			     0,
			     ROUND((value_p / (LAG(value_p) OVER (ORDER BY year_s ASC)) * 100) - 100, 0)) AS product_p
		FROM salary_product
		ORDER BY year_s
	)
	SELECT year_s,
	       salary_p,
	       product_p,
	       product_p-salary_p AS diference 
	FROM salary_product_final 
	ORDER BY year_s;
