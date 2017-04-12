--
-- Show the SQL exeution plan for a SQL plan baseline
--
SELECT *
FROM   TABLE(DBMS_XPLAN.DISPLAY_SQL_PLAN_BASELINE('&sql_handle',NULL)) t;

