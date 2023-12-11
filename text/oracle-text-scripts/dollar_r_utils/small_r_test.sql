connect sys/password as sysdba

drop user test2 cascade;

create user test2 identified by test2;
grant connect,resource,ctxapp,dba,unlimited tablespace to test2;

connect test2/test2
set echo on

alter session set events='30579 trace name context forever, level 268435456';

create table mytable (id number, text varchar2(2000));

begin
  for i in 1..100000 loop
    insert into mytable values (i, 'hello world');
  end loop;
end;
/

select count(*) from mytable;

exec ctx_ddl.create_preference('mystor', 'BASIC_STORAGE')
exec ctx_ddl.set_attribute('mystor', 'SMALL_R_ROW', 't')

create index myindex on mytable (text) indextype is ctxsys.context
parameters ('storage mystor');

select row_no, length(data) from dr$myindex$r;

select oat_id from ctxsys.dr$object_attribute where oat_name = 'SMALL_R_ROW';

column ixv_value format a10

create table foo as select * from dr$myindex$r;

delete from mytable where id = 90000;

commit;

drop table dr$myindex$r;

rename foo to dr$myindex$r;

select * from mytable where contains(text, 'hello') > 0 and id = 90000;

