set pagesize 100
column sql_text format a100
set linesize 200
set trims on
set pagesize 100
column sql_profile format a30
column sql_plan_baseline format a30
column exact_matching_signature format 99999999999999999999999

select sql_id,sql_plan_baseline,sql_profile,sql_text 
from v$sqlarea 
where sql_text like '%PROFTEST%'
and   (sql_profile is not null or sql_plan_baseline is not null)
order by sql_profile desc,sql_plan_baseline desc
/
