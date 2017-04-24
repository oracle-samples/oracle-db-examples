set pagesize 100

select sql_id,sql_text 
from v$sqlarea 
where sql_text like '%PATCHTEST%'
/
