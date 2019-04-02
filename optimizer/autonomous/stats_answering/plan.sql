set tab off
SET LINESIZE 220
SET PAGESIZE 500
column plan_table_output format a190
SELECT * FROM table(DBMS_XPLAN.DISPLAY_CURSOR(format=>'allstats last'));
