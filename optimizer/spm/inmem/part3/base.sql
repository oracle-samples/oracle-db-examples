set linesize 200
column sql_text format a80
column sql_handle format a20
column plan_name format a35
SELECT plan_name,sql_handle,sql_text,enabled, accepted 
FROM   dba_sql_plan_baselines
WHERE  sql_text LIKE '%SPM%';
