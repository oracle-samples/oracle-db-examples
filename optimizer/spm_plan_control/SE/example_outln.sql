@connect_admin

set echo on

--
-- WARNING - about to create SPM_TESTU user 
--
pause p...
drop user spm_testu cascade;

--##### EDIT HERE TO SET PASSWORD #####
create user spm_testu identified by <your_password_here>;
grant connect,resource to spm_testu;
grant unlimited tablespace to spm_testu;
grant select on v_$sqlarea to spm_testu;
grant select on v_$session to spm_testu;
grant select on v_$sql_plan_statistics_all to spm_testu;
grant select on v_$sql_plan to spm_testu;
grant select on v_$sql to spm_testu;
grant select on dba_sql_plan_baselines to spm_testu;
grant ADMINISTER SQL MANAGEMENT OBJECT to spm_testu;
grant create any outline to spm_testu;
grant alter any outline to spm_testu;
grant execute on dbms_outln to spm_testu;
grant select on dba_outlines to spm_testu;
--
-- Connect to the test user
--
@connect_user

@drop
exec dbms_outln.drop_by_cat('MY_TEST_CAT')

@tab
--
-- This will give is a FULL scan for our application query
--
drop index salesi;

var idv number
exec :idv := 5

--
-- Create the outline
--
column name format a40
column category format a40
CREATE OUTLINE sales_outline FOR CATEGORY my_test_cat
ON select sum(num) from sales where id < :idv;
select name,category from dba_outlines;
pause p...

@app_q
@app_q
--
-- The application query (above)
-- uses the FULL access method
--
pause p...

--
-- The new index will enable the INDEX access path
-- but the outline will prevent it.
--
create index salesi on sales (id);
pause p...

ALTER SESSION SET use_stored_outlines=MY_TEST_CAT;
@app_q
-- 
-- The outline is preventing the query from using the INDEX plan
-- 
pause p...

ALTER SESSION SET use_stored_outlines=DEFAULT;
declare
  report clob;
begin
  report := dbms_spm.migrate_stored_outline('category','MY_TEST_CAT');
  
end;
/
exec dbms_outln.drop_by_cat('MY_TEST_CAT')
select sql_text from dba_sql_plan_baselines where creator = user;
--
-- The stored outline has been migrated to SPM and then dropped (above) 
--
pause p...
@app_q
--
-- The FULL scan does not match the default INDEX plan so
-- we can't see the plan (above) because of bug 27500184
--
pause p...

explain plan for select sum(num) from sales where id < :idv;
SELECT *
FROM table(DBMS_XPLAN.DISPLAY(FORMAT=>'TYPICAL'));
--
-- The explain plan does however confirm the correct plan - maintained by the SQL plan baseline
--

