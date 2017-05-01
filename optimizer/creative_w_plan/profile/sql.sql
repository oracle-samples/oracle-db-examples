set pagesize 100
column sql_text format a100
set linesize 200
set trims on
set pagesize 100
column sql_profile format a30
column exact_matching_signature format 99999999999999999999999

select sql_id,exact_matching_signature,sql_profile,sql_text 
from v$sqlarea 
where sql_text like '%PROFTEST%'
order by sql_profile
/
