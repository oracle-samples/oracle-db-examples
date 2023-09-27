connect system/password

set echo on

drop user extest cascade;

create user  identified by extest default tablespace users temporary tablespace temp quota unlimited on users;

grant connect,resource,ctxapp to extest;

connect extest/extest

-- non partitioned example

create table bike_items (
  id number primary key,
  price number,
  descrip varchar2(40)
);

insert into bike_items values (1, 2.50,  'inner tube for MTB wheel');
commit;

create index bike_items_idx on bike_items (descrip)
indextype is ctxsys.context
parameters ('nopopulate sync(manual)');

exec ctx_ddl.recreate_index_online('bike_items_idx')
