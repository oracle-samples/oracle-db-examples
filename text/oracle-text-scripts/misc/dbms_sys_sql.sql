connect sys/oracle as sysdba

drop user my_public_user cascade;
drop user my_040100 cascade;
drop user enduser cascade;

create user MY_PUBLIC_USER identified by oracle;
grant connect,resource,ctxapp to MY_PUBLIC_USER;
grant execute on ctxsys.ctx_thes to MY_PUBLIC_USER;

create user MY_040100      identified by oracle;
grant connect,resource,ctxapp to MY_040100;
grant execute on ctxsys.ctx_thes to MY_040100;

create user ENDUSER        identified by oracle;
grant resource to ENDUSER;
grant create any table to ENDUSER;
grant execute on ctxsys.ctx_thes to ENDUSER;

grant execute on SYS.DBMS_SYS_SQL to MY_PUBLIC_USER;
grant execute on SYS.DBMS_SYS_SQL to MY_040100;

connect my_040100/oracle

create or replace procedure tab_create is
   uid number;
   sqltext varchar2(2000);
   myint integer;
begin
   select user_id into uid from all_users where username like 'ENDUSER';
   myint := sys.dbms_sys_sql.open_cursor();

   -- create a table
   sqltext := 'create table footest (bar varchar2(2000))';
   sys.dbms_sys_sql.parse_as_user( myint, sqltext, dbms_sql.native, uid );

   -- create a thesaurus
   sqltext := 'begin ctx_thes.create_thesaurus(''my_thes''); end;';
   sys.dbms_sys_sql.parse_as_user( myint, sqltext, dbms_sql.native, uid );
end;
/
show err

grant execute on tab_create to my_public_user;

connect my_public_user/oracle

exec my_040100.tab_create

connect sys/oracle as sysdba

select table_name, owner from all_tables where table_name = 'FOOTEST';

select ths_owner, ths_name from ctx_thesauri;
