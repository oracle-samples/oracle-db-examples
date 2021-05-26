--
-- This script explains a SQL statement in the cursor cache
-- and produces a hint report - useful for diagnosing 
-- SQL plan baseline issues
--
set echo off
set verify off
set feedback off
set long 10000000
set pagesize 10000
set linesize 250
set trims on
set tab off
column report format a200

whenever sqlerror exit

var ccount number
--
-- Get the SQL ID to test
--
accept sqlid prompt 'Enter the SQL ID: '

--
-- Check it's in cache
--
BEGIN
  select count(*) into :ccount from v$sqlarea where sql_id = '&sqlid';
  IF :ccount = 0
  THEN
    RAISE_APPLICATION_ERROR(-20002, 'SQL ID not found');
  END IF;
END;
/

--
-- Spool the report
--
spool spm_report

alter session set "_sql_plan_management_control"=4;

--
-- Explain plan
--
declare
  stmt clob; 
begin
  select sql_fulltext into stmt from v$sqlarea where sql_id = '&sqlid';
  execute immediate 'explain plan for '||stmt;
end;
/

alter session set "_sql_plan_management_control"=0;

select * from table(dbms_xplan.display(format=>'hint_report'));

spool off
