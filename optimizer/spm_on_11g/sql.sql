--
-- Take a look at the shared SQL areas cached in the shared pool
--
--
set trims on 
set linesize 250
column sql_text format a70
column is_bind_sensitive format a20
column is_bind_aware format a20
column is_shareable format a20
select sql_id,child_number,is_shareable,sql_text, executions,
is_bind_sensitive, is_bind_aware
from v$sql
where sql_text like '%sales%' order by 1, child_number;
