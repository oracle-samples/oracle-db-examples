set echo on

grant connect,resource,dba to mysys identified by mysys;
grant connect,resource,ctxapp to myruntime identified by myruntime;

connect mysys/mysys

drop table foo;

create table foo (text varchar2(2000));

insert into foo values ('cat dog rabbit');

exec ctx_query.remove_sqe('sqe_1')
exec ctx_query.store_sqe('sqe_1', 'dog')

create index fooind on foo(text) indextype is ctxsys.context;

grant select on foo to myruntime;


create or replace procedure run_query authid current_user as 
  counter number := 0;
begin
  select count(*) into counter from mysys.foo where contains (text, 'cat and sqe(sqe_1)') > 0;
  dbms_output.put_line('Counter is: '||counter);
end;
/
list
show errors

grant execute on run_query to myruntime;

set serveroutput on
exec run_query

connect myruntime/myruntime

set serverout on
exec mysys.run_query


