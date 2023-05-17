--
-- Load up a SQL tuning set with the test queries
--

set echo on
spool load_sqlset

declare
  stsname varchar2(100) := '&1';
  cur DBMS_SQLTUNE.SQLSET_CURSOR;
  cursor c1 is
    select name
    from   user_sqlset
    where  name = stsname;
begin
  for rec in c1
  loop
     dbms_sqltune.drop_sqlset(rec.name,user);
  end loop;
  dbms_sqltune.create_sqlset(stsname);
  open cur for 
    select value(p)
    from   table(DBMS_SQLTUNE.SELECT_CURSOR_CACHE('sql_text like ''select /* STS MY_TEST_QUERY%''',NULL, NULL, NULL, NULL, 1, NULL,'ALL')) p;
  dbms_sqltune.load_sqlset(sqlset_name => stsname, populate_cursor => cur);
END;
/
spool off
