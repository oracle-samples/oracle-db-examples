set index_name = 'fooindex'

set long 500000
set trimspool on
set linesize 999
set pagesize 0
set heading off

spool create_index.sql

select ctx_report.create_index( '&index_name' ) from dual;

spool off
