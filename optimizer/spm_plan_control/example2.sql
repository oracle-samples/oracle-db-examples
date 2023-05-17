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
--
-- Connect to the test user
--
@connect_user

--
-- These two steps are simply to reset the test if
-- the user was created in a previous run
--
@tab
@drop

@app_q
@app_q
--
-- The application query (above)
-- uses the INDEX access method
--
pause p...

--
-- Run the test query to get an example of the plan we want
--
@test_q
--
-- The plan above is the one we want
--
pause p...

--
-- Create the test procedure
--
set echo off
@proc2
set echo on

column sql_text format a50
column plan_hash_value format 99999999999999999
select sql_id,sql_text,plan_hash_value from v$sql where sql_text like '%sales where id < :idv%' and sql_text not like '%plan_hash%';

pause p...
set linesize 200
set trims on
set serveroutput on
--
-- exec add_my_plan(our_application_query, our_test_query, our_test_query_plan)
--
exec add_my_plan('f23qunrkxdgdt','82x4tj3z2vg23',1047182207)
set serveroutput off
--
-- Executed the procedure above
--
pause p...

@app_q
--
-- The application query (above) now uses 
-- the SQL plan baseline and FULL
--

pause p...

@app_q2
--
-- A query with the same signature (above) uses FULL too
-- 

