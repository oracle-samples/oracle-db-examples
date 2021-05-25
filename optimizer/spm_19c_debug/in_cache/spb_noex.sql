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
var spa_task_name varchar2(30);
var execution_name varchar2(30);
var report_text clob;

--
-- You must be licensed to use SPA
--
accept check prompt 'Enter YES/yes if you have a license to use SQL Performance Analyzer: ' default 'NO'


BEGIN
  IF upper('&check') != 'YES'
  THEN
    RAISE_APPLICATION_ERROR(-20001, 'License not confirmed');
  END IF;
END;
/

--
-- Get the SQL ID to test
--
accept sqlid prompt 'Enter the SQL ID: '

--
-- Check it's in cache
--
BEGIN
  select count(*) into :ccount from v$sql where sql_id = '&sqlid';
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

exec :spa_task_name := dbms_sqlpa.create_analysis_task(sql_id => '&sqlid');

exec dbms_sqlpa.set_analysis_task_parameter(:spa_task_name, 'disable_multi_exec', 'TRUE');

--
-- Enable the diag mode and run the task
--
alter session set "_sql_plan_management_control"=4;

exec :execution_name := dbms_sqlpa.execute_analysis_task (task_name => :spa_task_name, execution_type => 'explain plan');

alter session set "_sql_plan_management_control"=0;

--
-- Generate the report
--
exec :report_text := dbms_sqlpa.report_analysis_task (task_name => :spa_task_name, type => 'text', level => 'typical', section => 'all', execution_name => :execution_name);

select :report_text report from dual;

spool off
