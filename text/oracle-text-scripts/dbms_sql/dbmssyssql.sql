-- see comments in dbmssqltest.sql

connect sys/password as sysdba

drop user testuser cascade;
create user testuser identified by testuser default tablespace users temporary tablespace temp quota unlimited on users;
grant connect,resource,create table,ctxapp to testuser;
grant execute on ctx_ddl to testuser;


-- this procedure executes an arbitrary SQL statement (no binds or return values)
-- with a specific schema for objects

create or replace procedure execute_in_schema( schema varchar2, sqlstring varchar2 ) is

  curs number(38);
  rowcount integer;
  userid number;

begin

  curs := dbms_sys_sql.open_cursor;

  select user_id into userid from all_users where username = upper(schema);

  dbms_sys_sql.parse_as_user( 
     c             => curs,
     statement     => sqlstring,
     language_flag => 1,         /* ignored by DBMS_SQL */
     userid        => userid,
     schema        => schema     /* doesn't seem to make a difference if I include this or not */
  );

  rowcount := dbms_sys_sql.execute(curs);
  if rowcount is not null and rowcount > 0 then 
    dbms_output.put_line(rowcount || ' row(s) processed.');
  end if;

  dbms_sys_sql.close_cursor(curs);

end;
/
show err

set serverout on

exec execute_in_schema( 'TESTUSER', 'create table foo991 (x varchar2(200))' )
exec execute_in_schema( 'TESTUSER', 'insert into foo991 values (''hello world'')' )
exec execute_in_schema( 'TESTUSER', 'create index foo991index on foo991 (x)  indextype is ctxsys.context' )
exec execute_in_schema( 'TESTUSER', 'insert into foo991 values (''goodbye world'')' )
exec execute_in_schema( 'TESTUSER', 'begin ctx_ddl.sync_index(''FOO991INDEX''); end;' )
exec execute_in_schema( 'TESTUSER', 'begin ctx_ddl.optimize_index(''FOO991INDEX'', ''FULL''); end;' )


connect testuser/testuser

select tname from tab;

select token_text from dr$foo991index$i;

