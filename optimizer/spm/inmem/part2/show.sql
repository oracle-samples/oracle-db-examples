SELECT PLAN_TABLE_OUTPUT
FROM   
       TABLE(
         DBMS_XPLAN.DISPLAY_SQL_PLAN_BASELINE('&sql_handle','&plan_name','basic') 
       ) t
/
