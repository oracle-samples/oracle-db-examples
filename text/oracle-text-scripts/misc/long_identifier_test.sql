-- Long identifier test
-- Combined user.index strings fail in certain CTX_DDL procedures if combined length > 130 characters


connect system/manager

define user=auser
define table=a1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234

set echo on

drop user &&user cascade;

create user &&user identified by &&user default tablespace sysaux temporary tablespace temp quota unlimited on sysaux;

grant connect,resource,ctxapp to &&user;

connect &&user/&&user

-- non partitioned example

create table &&table (
  id number primary key,
  price number,
  descrip varchar2(40)
);

insert into &&table values (1, 2.50,  'inner tube for MTB wheel');
commit;

create index &&table on &&table (descrip)
indextype is ctxsys.context
parameters ('nopopulate sync(manual)');

-- this works OK
exec ctx_ddl.recreate_index_online('&&table')

-- this does not work
exec ctx_ddl.recreate_index_online('&&user..&&table')

-- check length of combined identifiers - will fail if > 130
select length('&&user..&&table') from dual;
