SET LINESIZE 130
SET PAGESIZE 1000
column plan_table_output format a120

SELECT * FROM table(DBMS_XPLAN.DISPLAY_CURSOR(format=>'typical'));
