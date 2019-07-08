set echo on

alter system flush shared_pool;
alter index bob_pk invisible;
alter index bob_idx invisible;

@@q

declare
  n pls_integer;
begin
  for i in 1..100000
  loop
     execute immediate 'select /* HELLO */ num from bob where id = 100' into n;
  end loop;
end;
/

exec dbms_sqltune.drop_sqlset('MY_TEST_STS')
exec dbms_sqltune.create_sqlset('MY_TEST_STS')

select /* HELLO */ num from bob where id = 100;

DECLARE
  cur DBMS_SQLTUNE.SQLSET_CURSOR;
BEGIN
  OPEN cur FOR
    SELECT value(p)
      FROM table(
        DBMS_SQLTUNE.SELECT_CURSOR_CACHE(basic_filter=>'sql_id = ''8c2dqym0cbqvj''', 
            attribute_list=>'ALL')) P;

  DBMS_SQLTUNE.LOAD_SQLSET(sqlset_name => 'MY_TEST_STS', populate_cursor => cur);
END;
/

alter index bob_pk visible;
alter index bob_idx visible;

set echo off
