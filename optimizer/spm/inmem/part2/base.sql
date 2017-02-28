set linesize 150
column sql_text format a50
column plan_name format a35
column sql_handle format a20
SELECT sql_handle,plan_name,sql_text,enabled, accepted 
FROM   dba_sql_plan_baselines
WHERE  sql_text LIKE '%SPM%';
