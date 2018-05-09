--
-- Show statistics for FACT1
--
-- The histogram query is by Tim Hall: https://oracle-base.com/articles/12c/histograms-enhancements-12cr1
--
select table_name,num_rows,sample_size,stale_stats from user_tab_statistics where  table_name = 'FACT1';

select table_name,column_name,low_value,high_value,sample_size,histogram from user_tab_col_statistics where table_name = 'FACT1';

SELECT '<=' || endpoint_value AS range,
       endpoint_value - (LAG(endpoint_value, 1, -1) OVER (ORDER BY endpoint_value)+1) + 1 AS vals_in_range,
       endpoint_number - LAG(endpoint_number, 1, 0) OVER (ORDER BY endpoint_value) AS frequency
FROM   user_tab_histograms
WHERE  table_name  = 'FACT1'
AND    column_name = 'NUM1'
ORDER BY endpoint_value;
