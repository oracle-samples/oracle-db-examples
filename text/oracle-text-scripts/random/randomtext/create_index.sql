
exec ctx_output.start_log('log1.log')

set timing on

create index textindex on mydocs2(text) 
indextype is ctxsys.context
parameters ('memory 500M sync(on commit)')
/

set timing off

exec ctx_output.end_log

