REM
REM REQUIRE: plan_table (created by the script ?/rdbms/admin/utlxplan.sql)
REM 

set pagesize 600
set long     4000
set long     2000
set tab      off
set linesize 130
set underline =
col TQID         format A4
col "SLAVE SQL"  format A95 WORD_WRAP

@?/rdbms/admin/utlxplp

REM
REM Print slave sql
REM
select decode(object_node,null,'',
              substr(object_node,length(object_node)-3,1) || ',' || 
              substr(object_node,length(object_node)-1,2)) TQID,
       other "SLAVE SQL"
  from plan_table
  where other is not null and
        timestamp >= (select max(timestamp) from plan_table where id=0);

