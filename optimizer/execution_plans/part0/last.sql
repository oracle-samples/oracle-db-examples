select prev_sql_id, prev_child_number 
from   v$session 
where  sid=userenv('sid') 
and    username is not null 
and    prev_hash_value <> 0;

