connect / as sysdba

set echo on

--
-- WARNING - about to create SPM_TESTU user 
--
--drop user spm_testu cascade;

create user spm_testu identified by spm_testu;
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
connect spm_testu/spm_testu

--
-- These two steps are simply to reset the test if
-- the user was created in a previous run
--
@tab
@drop

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
@proc
set echo on

set linesize 200
set trims on
set serveroutput on
exec set_my_plan('f23qunrkxdgdt','82x4tj3z2vg23',1047182207)
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

