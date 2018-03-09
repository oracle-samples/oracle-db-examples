set linesize 220 tab off pagesize 1000 trims on
column plan_table_output format a120

SELECT *
FROM table(DBMS_XPLAN.DISPLAY_CURSOR(FORMAT=>'LAST ADVANCED'));
