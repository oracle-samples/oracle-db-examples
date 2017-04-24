column signature format 99999999999999999999
column sql_text format a80
column name format a35
set linesize 1000
set trims on

select name,signature,sql_text,status
from   dba_sql_profiles;
