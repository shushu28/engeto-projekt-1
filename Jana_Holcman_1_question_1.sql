-- research question no. 1

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
