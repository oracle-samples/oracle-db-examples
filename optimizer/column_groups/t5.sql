column the_sqlid new_value sqlid

select sql_id the_sqlid
from   v$sqlarea
where  sql_text like 'select /* MY_TEST_QUERY%';

define sqlid
 
--
-- Scan the tables access by the query
-- and spool a script we'll run to create them
--
@@corr_from_sqlid &sqlid 100 y
