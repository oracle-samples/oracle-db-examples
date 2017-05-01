set linesize 200
column sql_handle format a30
column plan_name format a30
column sql_text format a80
column signature format 999999999999999999999999999

SELECT signature,sql_handle,plan_name,sql_text,enabled, accepted
FROM   dba_sql_plan_baselines
WHERE  sql_text LIKE '%PROFTEST%';

