-- primary table

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
