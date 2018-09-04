--
-- Create a SQL Plan Baseline for a FULL plan
-- and then add a new index to the table so that
-- an INDEX plan is the most optimimal.
--
-- In EE, we will get a new SQL Plan Baseline with the index plan
-- In SE, we will not get a new SQL Plan Baseline because only one is allowed
--
-- A side-effect is that the new (index plan) cursor in SE will be invalidated each time it is executed.
-- This is Bug #27500184
--
set linesize 280
set trims on
set pagesize 200
set tab off
set feedback on
column plan_name format a30
column sql_handle format a30
column sql_text format a50
column plan_table_output format a150
show user
set echo on
--
-- Drop existing SQL plan baselines (with HELLO in the text)
--
declare
  l_plans_dropped  pls_integer;
BEGIN
  for rec in (select distinct sql_handle from dba_sql_plan_baselines where sql_text like '%HELLO%' and creator = user)
  loop
      l_plans_dropped := dbms_spm.drop_sql_plan_baseline (
        sql_handle => rec.sql_handle,
        plan_name  => null);
  end loop;
end;
/

--
-- (Drop and) create a table BOB
--
drop table bob purge;

create table bob (id number(10), num number(10));

begin
  for i in 1..10000
  loop
    insert into bob values (i,i);
  end loop;
end;
/
commit;

exec dbms_stats.gather_table_stats (ownname=>null,tabname=>'bob');

--
-- This is the test query
--
select /* HELLO */ num from bob where id = 100;
select /* HELLO */ num from bob where id = 100;
select /* HELLO */ num from bob where id = 100;

--
-- Load the query's plan to create a SQL plan baseline
--
var r number
exec :r :=  dbms_spm.load_plans_from_cursor_cache('8c2dqym0cbqvj')

--
-- Check that the SQL plan baseline exists
--
select sql_text,accepted,enabled,sql_handle,plan_name from dba_sql_plan_baselines where sql_text like '%HELLO%';

pause p...

--
-- Check to see if the SQL statement is using the SQL plan baseline
--
select /* HELLO */ num from bob where id = 100;
select * from table(dbms_xplan.display_cursor(format=>'TYPICAL'));

pause p...

--
-- Creating the index will give us the potential to use a new INDEX plan
-- but the SQL plan baseline will prevent this
--
create unique index bobi on bob(id);

--
-- Execute again - the INDEX plan is available but SPM prevents its use
--
select /* HELLO */ num from bob where id = 100;
select /* HELLO */ num from bob where id = 100;
select /* HELLO */ num from bob where id = 100;
select /* HELLO */ num from bob where id = 100;
select /* HELLO */ num from bob where id = 100;
--
-- SE: Plan is not available because cursor is being invalidated
-- EE: Plan is available
--
select * from table(dbms_xplan.display_cursor(format=>'TYPICAL'));
pause p...
--
-- Check V$SQL
-- SE: Not visible
-- EE: Visible
--
select sql_id from v$sql where sql_text = 'select /* HELLO */ num from bob where id = 100';

pause p...
--
-- Check V$SQL_SHARED_CURSOR
--
select * from  v$sql_shared_cursor where sql_id = '8c2dqym0cbqvj' order by child_number;

pause p...

--
-- In SE there will be a single SQL plan baseline
-- In EE, there will be two SQL plan baselines - the new INDEX plan is ready for evolution
--
select sql_text,accepted,enabled,sql_handle,plan_name from dba_sql_plan_baselines;

show user
