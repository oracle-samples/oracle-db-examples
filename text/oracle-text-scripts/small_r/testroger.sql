connect / as sysdba
set echo on
set timing on

@small_r_conversion3.sql

-- create bigfile tablespace testtbs datafile '/home/oracle/app/oracle/oradata/testtbs1.dbf' size-- 1G autoextend on segment space management auto;

alter user roger default tablespace testtbs;

--grant connect,resource,ctxapp,unlimited tablespace to roger;

connect roger/roger

drop table t;
-- drop backup $R table from previous run (if any)
--drop table dr$i$ro;

create table t(id number, c varchar2(2000));

begin
  for i in 1 .. 35002 loop
    insert into t values (i, 'x'||i);
  end loop;
end;
/

commit;

exec ctx_output.start_log('12102_index.log')

create index i on t(c) indextype is ctxsys.context parameters('storage mystor memory 500M') parallel 4;

exec ctx_ddl.sync_index('i', '500000000')

select row_no, length(data) from dr$i$r;

exec ctx_output.end_log;

connect / as sysdba

set serveroutput off

drop table roger.dr$i$ro;

exec sys.small_r_convert.convert_index('roger', 'i')

connect roger/roger

select row_no, length(data) from dr$i$r;

column c format a30
select * from t where contains (c, 'x2') > 0;
select * from t where contains (c, 'x200000002') > 0;

drop table dr$i$ro;

connect / as sysdba

--set serveroutput off
--exec small_r_convertback.convert_index('roger', 'i')

connect roger/roger

select row_no, length(data) from dr$i$r;

column c format a30
select * from t where contains (c, 'x2') > 0;
select * from t where contains (c, 'x200000002') > 0;

select IXV_VALUE from ctxsys.ctx_index_values where ixv_index_owner = 'ROGER' and ixv_index_name = 'I' and ixv_attribute = 'SMALL_R_ROW';

delete from dr$i$r where row_no = 1;

select row_no, length(data) from dr$i$r;

commit;
set serverout on
exec ctx_diag.k_to_r('dr$i$k', 'dr$i$r', 35000, TRUE)

select row_no, length(data) from dr$i$r;
