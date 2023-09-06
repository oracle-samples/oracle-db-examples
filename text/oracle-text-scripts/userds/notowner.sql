connect sys/password as sysdba

drop user user1 cascade;
drop user user2 cascade;

create user user1 identified by user1 default tablespace users temporary tablespace temp quota unlimited on users;
create user user2 identified by user2 default tablespace users temporary tablespace temp quota unlimited on users;
grant connect,resource,ctxapp to user1;
grant connect,resource,ctxapp to user2;

connect user1/user1

create table mytab(col1 varchar2(20), col2 varchar2(20));
insert into mytab values ('x', 'y');

grant index on mytab to user2;
-- grant select on mytab to user2;

exec ctx_ddl.create_preference('myds', 'MULTI_COLUMN_DATASTORE')
exec ctx_ddl.set_attribute('myds', 'COLUMNS', 'col1,col2')

connect user2/user2

create index user2.myind on user1.mytab(col1) indextype is ctxsys.context parameters ('datastore user1.myds');




