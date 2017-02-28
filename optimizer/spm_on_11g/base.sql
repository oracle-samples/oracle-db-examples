--
-- List SQL plan baselines
--
column enabled format a10
column sql_text format a70
column plan_name format a40
column sql_handle format a25
column accepted format a10
set linesize 200
SELECT sql_text,sql_handle, plan_name, enabled, accepted
FROM   dba_sql_plan_baselines  
order by sql_handle
/
