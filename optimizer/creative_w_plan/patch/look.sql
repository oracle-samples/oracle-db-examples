column signature format 9999999999999999999999
column exact_matching_signature format 9999999999999999999999
column sql_text format a60
column sql_patch format a15
column status format a15
set linesize 300
set trims on
select signature, sql_text,status from dba_sql_patches;

select sql_text,sql_patch,exact_matching_signature
from   v$sqlarea
where  sql_patch is not null
order  by 1;
