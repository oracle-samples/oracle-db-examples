-- Run Oracle Text commands as another user with dbms_sql
-- where you want control over the user's session rather than having them
-- log directly into the database

-- Oracle text's CTX_DDL package does NOT work using DBMS_SQL. It does not
-- seem to inherit the schema properly.
-- see the accompanying dbmssyssql.sql which uses (the undocumented?) 
-- DBMS_SYS_SQL instead, which does work
-- Oracle's LiveSQL uses DBMS_SYS_SQL to run user commands under SYS control.

connect sys/oracle as sysdba

drop user testuser cascade;
create user testuser identified by testuser default tablespace users temporary tablespace temp quota unlimited on users;
grant connect,resource,ctxapp to testuser;


-- this procedure executes an arbitrary SQL statement (no binds or return values)
-- with a specific schema for objects

create or replace procedure execute_in_schema( schema varchar2, sqlstring varchar2 ) is

  curs integer;
  rowcount integer;

begin

  curs := dbms_sql.open_cursor;

  dbms_sql.parse( 
     c             => curs,
     language_flag => 1,             /* ignored by DBMS_SQL */
     statement     => sqlstring,
     schema        => schema,
     container     => null           /* no default value for this param */
  );

  rowcount := dbms_sql.execute(curs);
  if rowcount is not null and rowcount > 0 then 
    dbms_output.put_line(rowcount || ' row(s) processed.');
  end if;

  dbms_sql.close_cursor(curs);

end;
/
list
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
