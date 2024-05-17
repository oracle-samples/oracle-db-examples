
set timing on

exec ctx_output.start_log('eloc.log');

create index eloc_index on eloc_part(key) 
indextype is ctxsys.context
parameters ('memory 400m')
parallel 4
local
/

exec ctx_output.end_log
