-- research question no. 5

CREATE VIEW t_jana_holcman_otazka_5 AS
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
		FROM t_jana_holcman_project_sql_primary_final AS primary_table 
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
	), 
	gdp_cz AS 
	(
		SELECT year AS year_h,
		       gdp
		FROM t_jana_holcman_project_sql_secondary_final AS secondary_table 
		WHERE secondary_table.country = 'Czech Republic' 
		  AND (year IN (SELECT year_s FROM salary_product_final))
	), 
	salary_product_gdp AS
	(
		SELECT * FROM salary_product_final 
		INNER JOIN gdp_cz ON salary_product_final.year_s = gdp_cz.year_h
	), 
	salary_product_gdp_dif AS 
	(
		SELECT year_s, salary_p,product_p,
			   IF((LAG(year_s) OVER (ORDER BY year_s ASC) IS NULL), 
		  	   0,
		  	   ROUND((gdp / (LAG(gdp) OVER (ORDER BY year_s ASC)) * 100) - 100, 0)) AS gdp_p
		FROM salary_product_gdp 
		ORDER BY year_s
	), 
	salary_product_gdp_dif_final AS 
	(
		SELECT *,
			   IF((LAG(year_s) OVER (ORDER BY year_s ASC) IS NULL), 
			     0,
			     salary_p - LAG(salary_p) OVER (ORDER BY year_s ASC)) AS salary_d,
			   IF((LAG(year_s) OVER (ORDER BY year_s ASC) IS NULL), 
			     0,
			     product_p - LAG(product_p) OVER (ORDER BY year_s ASC)) AS product_d,
			   IF((LAG(year_s) OVER (ORDER BY year_s ASC) IS NULL), 
			     0,
			     gdp_p - LAG(gdp_p) OVER (ORDER BY year_s ASC)) AS gdp_d
		FROM salary_product_gdp_dif
	)
	SELECT * FROM salary_product_gdp_dif_final ORDER BY year_s;
