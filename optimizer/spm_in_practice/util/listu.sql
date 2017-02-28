REM
REM  List SQL plan baselines for a specified user
REM

set linesize 200
set trims on
set tab off
column last_executed format a30
column sql_text format a40
column sql_handle format a40
column plan_name format a35
column signature format 999999999999999999999

select signature,plan_name,sql_handle,sql_text, accepted, enabled
from dba_sql_plan_baselines 
where parsing_schema_name = '&1'
/
