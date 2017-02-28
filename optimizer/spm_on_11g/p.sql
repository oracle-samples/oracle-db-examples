set linesize 130
set pagesize 1000
SELECT * 
FROM   TABLE(DBMS_XPLAN.DISPLAY_CURSOR());
