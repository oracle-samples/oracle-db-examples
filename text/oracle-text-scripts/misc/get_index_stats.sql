define index_name = 'fooindex'

set long 500000
set trimspool on
set linesize 999
set pagesize 0
set heading off

variable myclob clob

exec dbms_lob.createtemporary ( :myclob , true )

exec ctx_report.index_stats( &index_name , :myclob, true, 500 )

spool index_stats.lst

print myclob
spool off

