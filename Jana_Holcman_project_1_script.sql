-- pomocná tabulka č. 1

CREATE TABLE IF NOT EXISTS t_jana_holcman_project_sql_primary_final AS (
SELECT 'salary' AS 'type',ROUND(AVG(x.value),2) 'value',y.name AS 'name',x.payroll_year 'year_c','' AS 'price_value','Kč' AS 'unit' FROM czechia_payroll x
LEFT JOIN czechia_payroll_industry_branch y on x.industry_branch_code = y.code  
WHERE unit_code=200 AND calculation_code=100 GROUP BY industry_branch_code,payroll_year
UNION ALL
SELECT 'product' AS 'type',ROUND(AVG(x1.value),2) 'value',y1.name 'name',x1.year_c 'year_c',y1.price_value 'price_value', y1.price_unit 'unit' 
FROM (SELECT value,category_code,year(date_from) year_c,region_code FROM czechia_price) x1
LEFT JOIN czechia_price_category y1 on x1.category_code  = y1.code
GROUP BY category_code,year_c
);

-- pomocná tabulka č. 2

CREATE TABLE IF NOT EXISTS t_jana_holcman_project_sql_secondary_final AS (
	SELECT country,year,gdp,population,gini,taxes FROM economies  
	WHERE country IN (SELECT country FROM countries WHERE continent='Europe')
);

-- úkol č. 1
CREATE VIEW t_jana_holcman_otazka_1 AS
	SELECT x.*, IF((x.name <> LAG(x.name) OVER (ORDER BY x.name ASC , x.year_c ASC) or LAG(x.name) OVER (ORDER BY x.name ASC , x.year_c ASC) is NULL), 100 ,ROUND((x.value / (LAG(x.value) OVER (ORDER BY x.name ASC , x.year_c ASC))*100),0)) AS percentage
	FROM t_jana_holcman_project_sql_primary_final x
	WHERE type='salary' AND name is not null
	ORDER BY name ASC, year_c ASC;

-- úkol č. 2

CREATE VIEW t_jana_holcman_otazka_2 AS
WITH t1 AS
(
	SELECT x.name name, x.value salary,x.year_c year_c FROM t_jana_holcman_project_sql_primary_final x 
		WHERE `type` = 'salary' AND name is not null
), t2 AS 
(
	SELECT y.name product,y.value price,y.price_value price_value,y.unit unit,y.year_c year_p FROM t_jana_holcman_project_sql_primary_final y 
		WHERE `type` = 'product' AND (name = 'Chléb konzumní kmínový' or name = 'Mléko polotučné pasterované')
), t3 AS 
(
	SELECT * FROM t1
	INNER JOIN t2 on t1.year_c = t2.year_p
), t4 AS 
(
	SELECT ROUND(avg(salary),2) salary,ROUND(AVG(price),2) price,ROUND(avg(salary)/AVG(price),0) quantity,year_c year_c,product product FROM t3
	GROUP BY year_c,product
), t5 AS
(
	SELECT * FROM t4 ORDER BY year_c ASC limit 2
), t6 AS
(
	SELECT * FROM t4 ORDER BY year_c DESC limit 2
)
SELECT * FROM t5 UNION ALL SELECT * FROM t6 ORDER BY product ASC, year_c ASC;

-- úkol č. 3

CREATE VIEW t_jana_holcman_otazka_3 AS
WITH t1 AS
(
	SELECT x.*, IF((x.name <> LAG(x.name) OVER (ORDER BY x.name ASC , x.year_c ASC) or LAG(x.name) OVER (ORDER BY x.name ASC , x.year_c ASC) is NULL), 0 ,ROUND((x.value / (LAG(x.value) OVER (ORDER BY x.name ASC , x.year_c ASC))*100)-100,0)) AS increase_p
	FROM t_jana_holcman_project_sql_primary_final x
	WHERE type='product'
	ORDER BY name ASC, year_c ASC
), t2 AS
(
	SELECT name, ROUND(sum(increase_p),0) grow FROM t1
	GROUP BY name 
)
SELECT * FROM t2 ORDER BY grow ASC;

-- úkol č. 4

CREATE VIEW t_jana_holcman_otazka_4 AS
WITH t1 AS
(
	SELECT x.year_c year_s,ROUND(avg(x.value),0) value_s FROM t_jana_holcman_project_sql_primary_final x 
	WHERE x.type = 'salary' AND x.name IS NOT NULL
	GROUP BY x.year_c
), t2 AS
(
	SELECT y.year_c year_p,ROUND(avg(y.value),0) value_p FROM t_jana_holcman_project_sql_primary_final y 
	WHERE type = 'product' AND name IS NOT NULL
	GROUP BY y.year_c
), t3 AS 
(
	SELECT * FROM t1 INNER JOIN t2 ON t1.year_s=t2.year_p
), t4 AS 
(
	SELECT year_s,
	value_s,IF((LAG(year_s) OVER (ORDER BY year_s ASC) is NULL), 0 ,ROUND((value_s / (LAG(value_s) OVER (ORDER BY year_s ASC))*100)-100,0)) AS salary_p,
	value_p,IF((LAG(year_s) OVER (ORDER BY year_s ASC) is NULL), 0 ,ROUND((value_p / (LAG(value_p) OVER (ORDER BY year_s ASC))*100)-100,0)) AS product_p
	FROM t3 ORDER BY year_s
)
SELECT year_s,salary_p,product_p,product_p-salary_p diference FROM t4 ORDER BY year_s;

-- úkol č. 5

CREATE VIEW t_jana_holcman_otazka_5 AS
WITH t1 AS
(
	SELECT x.year_c year_s,ROUND(avg(x.value),0) value_s FROM t_jana_holcman_project_sql_primary_final x 
	WHERE x.type = 'salary' AND x.name IS NOT NULL
	GROUP BY x.year_c
), t2 AS
(
	SELECT y.year_c year_p,ROUND(avg(y.value),0) value_p FROM t_jana_holcman_project_sql_primary_final y 
	WHERE type = 'product' AND name IS NOT NULL
	GROUP BY y.year_c
), t3 AS 
(
	SELECT * FROM t1 INNER JOIN t2 ON t1.year_s=t2.year_p
), t4 AS 
(
	SELECT year_s,
	value_s,IF((LAG(year_s) OVER (ORDER BY year_s ASC) is NULL), 0 ,ROUND((value_s / (LAG(value_s) OVER (ORDER BY year_s ASC))*100)-100,0)) AS salary_p,
	value_p,IF((LAG(year_s) OVER (ORDER BY year_s ASC) is NULL), 0 ,ROUND((value_p / (LAG(value_p) OVER (ORDER BY year_s ASC))*100)-100,0)) AS product_p
	FROM t3 ORDER BY year_s
), t5 AS 
(
	SELECT YEAR year_h,gdp
	FROM t_jana_holcman_project_sql_secondary_final z 
	WHERE z.country = 'Czech Republic' AND (year IN (SELECT year_s FROM t4))
), t6 AS
(
	SELECT * FROM t4 INNER JOIN t5 ON t4.year_s=t5.year_h
), t7 AS 
(
	SELECT year_s, salary_p,product_p,
	IF((LAG(year_s) OVER (ORDER BY year_s ASC) is NULL), 0 ,ROUND((gdp / (LAG(gdp) OVER (ORDER BY year_s ASC))*100)-100,0)) AS gdp_p
	FROM t6 ORDER BY year_s
), t8 AS 
(
	SELECT *,
	IF((LAG(year_s) OVER (ORDER BY year_s ASC) is NULL), 0 ,salary_p - LAG(salary_p) OVER (ORDER BY year_s ASC)) AS salary_d,
	IF((LAG(year_s) OVER (ORDER BY year_s ASC) is NULL), 0 ,product_p - LAG(product_p) OVER (ORDER BY year_s ASC)) AS product_d,
	IF((LAG(year_s) OVER (ORDER BY year_s ASC) is NULL), 0 ,gdp_p - LAG(gdp_p) OVER (ORDER BY year_s ASC)) AS gdp_d
	FROM t7
)
SELECT * FROM t8 ORDER BY year_s;
