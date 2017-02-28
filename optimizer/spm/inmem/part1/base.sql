set linesize 150
column sql_text format a100
SELECT sql_text,enabled, accepted 
FROM   dba_sql_plan_baselines
WHERE  sql_text LIKE '%SPM%';
