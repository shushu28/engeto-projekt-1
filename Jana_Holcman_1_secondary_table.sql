-- secondary table

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
