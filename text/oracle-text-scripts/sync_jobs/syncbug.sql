connect sys as sysdba

drop user testuser cascade;

create user testuser identified by testuser default tablespace users temporary tablespace temp quota unlimited on users;

grant connect,resource,ctxapp to testuser;

connect testuser/testuser

create table foo (bar varchar2(200));

create index fooindex on foo(bar) indextype is ctxsys.context
parameters( 'sync (every sysdate+1/24/60)' );

drop index fooindex;

drop index fooindex force;

create index fooindex on foo(bar) indextype is ctxsys.context
parameters( 'sync (every sysdate+1/24/60)' );
