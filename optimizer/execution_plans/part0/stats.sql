set linesize 210 tab off pagesize 1000 trims on
column plan_table_output format a200

SELECT *
FROM table(DBMS_XPLAN.DISPLAY_CURSOR(FORMAT=>'ALLSTATS LAST ADVANCED'));
