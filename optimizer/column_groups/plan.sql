set linesize 200
set trims on
set tab off
set pagesize 1000
column plan_table_output format a100

SELECT *
FROM table(DBMS_XPLAN.DISPLAY_CURSOR(FORMAT=>'TYPICAL'));
