spool t3

column the_sqlid new_value sqlid

select sql_id the_sqlid
from   v$sqlarea
where  sql_text like 'select /* MY_TEST_QUERY%';

define sqlid
 
@cg_from_sqlid &sqlid y

spool off
