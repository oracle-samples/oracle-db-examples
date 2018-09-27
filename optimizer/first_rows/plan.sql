column plan_table_output format a100

SELECT *
FROM table(DBMS_XPLAN.DISPLAY_CURSOR(FORMAT=>'TYPICAL -PREDICATE'));


