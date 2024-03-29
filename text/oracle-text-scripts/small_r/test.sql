connect / as sysdba
set echo on
set timing on

--@small_r_conversion2.sql
--@small_r_convertback.sql

--create bigfile tablespace testtbs datafile '/home/oracle/app/oracle/oradata/testtbs1.dbf' size-- 1G autoextend on segment space management auto;

--create user testuser identified by testuser default tablespace testtbs;

--grant connect,resource,ctxapp,unlimited tablespace to testuser;

connect testuser/testuser

--drop table t;
-- drop backup $R table from previous run (if any)
--drop table dr$i$ro;

--create table t(id number, c varchar2(2000));

begin
  for i in 200000021 .. 256883714 loop
    insert into t values (i, 'x'||i);
  end loop;
end;
/

commit;

--exec ctx_ddl.drop_preference  ('mystor')
--exec ctx_ddl.create_preference('mystor', 'basic_storage')
-- exec ctx_ddl.set_attribute    ('mystor', 'small_r_row', 't')

exec ctx_output.start_log('12102_index.log')

--create index i on t(c) indextype is ctxsys.context parameters('storage mystor memory 500M') parallel 4;

exec ctx_ddl.sync_index('i', '500000000')

select row_no, length(data) from dr$i$r;

exec ctx_output.end_log;

connect / as sysdba

set serveroutput off

drop table testuser.dr$i$ro;

exec sys.small_r_convert.convert_index('testuser', 'i')

connect testuser/testuser

select row_no, length(data) from dr$i$r;

column c format a30
select * from t where contains (c, 'x2') > 0;
select * from t where contains (c, 'x200000002') > 0;

drop table dr$i$ro;

connect / as sysdba

set serveroutput off
exec small_r_convertback.convert_index('testuser', 'i')

connect testuser/testuser

select row_no, length(data) from dr$i$r;

column c format a30
select * from t where contains (c, 'x2') > 0;
select * from t where contains (c, 'x200000002') > 0;

select IXV_VALUE from ctxsys.ctx_index_values where ixv_index_owner = 'TESTUSER' and ixv_index_name = 'I' and ixv_attribute = 'SMALL_R_ROW';
