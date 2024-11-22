-- an "exotic name" is an object name which must be contained in double quotes
-- the simplest example is a table with a mixed case name, such as "Abc".
-- normally if I do 'create table Abc' it creates a table called "ABC". If
-- I want the case maintained I must do 'create table "Abc"'.
-- exotic tables can contain any (?) characters, including spaces and quotes.
-- this is a test uses a standard table name, but an exotic index name

connect system/password

drop user testuser cascade;
create user testuser identified by testuser default tablespace sysaux temporary tablespace temp quota unlimited on sysaux;

grant connect,resource,ctxapp to testuser;

connect testuser/testuser

create table foo (bar varchar2(200));

insert into foo values ('hello world');

create index " foo'bar" on foo(bar) indextype is ctxsys.context;

select table_name from user_tables;

select * from foo where contains(bar, 'hello') > 0;

exec ctx_ddl.sync_index('" foo''bar"')
exec ctx_ddl.optimize_index('" foo''bar"', 'FULL')

