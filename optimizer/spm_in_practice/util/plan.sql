set linesize 200
set tab off
set pagesize 1000
column plan_table_output format a180

SELECT *
FROM table(DBMS_XPLAN.DISPLAY_CURSOR(FORMAT=>'LAST'));
