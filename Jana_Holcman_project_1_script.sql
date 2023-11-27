-- pomocná tabulka č. 1

CREATE TABLE IF NOT EXISTS t_jana_holcman_project_sql_primary_final AS
  (SELECT 'salary' AS 'type',
          ROUND(AVG(cp.value), 2) AS 'value',
          cpi.name AS 'name',
          cp.payroll_year AS 'year_c',
          '' AS 'price_value',
          'Kč' AS 'unit'
   FROM czechia_payroll AS cp
   LEFT JOIN czechia_payroll_industry_branch AS cpi ON cp.industry_branch_code = cpi.code
   WHERE unit_code = 200
     AND calculation_code = 100
   GROUP BY industry_branch_code,
            payroll_year
   UNION ALL SELECT 'product' AS 'type',
                    ROUND(AVG(x1.value), 2) AS 'value',
                    y1.name AS 'name',
                    x1.year_c AS 'year_c',
                    y1.price_value AS 'price_value',
                    y1.price_unit AS 'unit'
   FROM
     (SELECT value,
             category_code,
             year(date_from) AS year_c,
             region_code
      FROM czechia_price) AS price
   LEFT JOIN czechia_price_category AS pricecat ON price.category_code = pricecat.code
   GROUP BY category_code,
            year_c
   );

-- pomocná tabulka č. 2

CREATE TABLE IF NOT EXISTS t_jana_holcman_project_sql_secondary_final AS
  (SELECT country,
          year,
          gdp,
          population,
          gini,
          taxes
   FROM economies
   WHERE country IN
       (SELECT country
        FROM countries
        WHERE continent = 'Europe')
   );

-- úkol č. 1

CREATE VIEW t_jana_holcman_otazka_1 AS
	SELECT primary_table.*, 
		   IF((primary_table.name <> LAG(primary_table.name) OVER (ORDER BY primary_table.name ASC, primary_table.year_c ASC) or LAG(primary_table.name) OVER (ORDER BY primary_table.name ASC, primary_table.year_c ASC) IS NULL), 
		   	 100,
		   	 ROUND((primary_table.value / (LAG(primary_table.value) OVER (ORDER BY primary_table.name ASC, primary_table.year_c ASC)) * 100), 0)) AS percentage
	FROM t_jana_holcman_project_sql_primary_final AS primary_table
	WHERE type = 'salary' 
	  AND name IS NOT NULL
	ORDER BY name ASC, 
			 year_c ASC;

-- úkol č. 2

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

-- úkol č. 4

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

-- úkol č. 5

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
