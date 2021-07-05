--
-- This script explains a SQL statement in the cursor cache
-- NOTE - it will fail for very long SQL statements
-- If you have a license to use SQL performance advisor, you
-- can use that instead to parse SQL statements in the cursor
-- cache.
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

var ccount number

--
-- Check it's in cache
--
BEGIN
  select count(*) into :ccount from v$sqlarea where sql_id = '&1';
  IF :ccount = 0
  THEN
    RAISE_APPLICATION_ERROR(-20002, 'SQL ID not found');
  END IF;
END;
/

--
-- Explain plan
--
declare
  stmt clob; 
begin
  select sql_fulltext into stmt from v$sqlarea where sql_id = '&1';
  execute immediate 'explain plan for '||stmt;
end;
/
--
-- No need to display
--
--select * from table(dbms_xplan.display(format=>'hint_report'));
