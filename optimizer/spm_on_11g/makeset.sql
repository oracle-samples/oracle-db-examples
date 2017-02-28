--
-- Loads SQL from shared pool into a SQL tuning set
-- Note: Requires Diagnostic and Tuning Pack Licence
--
BEGIN
  DBMS_SQLTUNE.DROP_SQLSET( sqlset_name => 'my_workload' );
END;
/

BEGIN
  DBMS_SQLTUNE.CREATE_SQLSET(
    sqlset_name => 'my_workload', 
    description  => 'My workload');
END;
/

DECLARE
  c_sqlarea_cursor DBMS_SQLTUNE.SQLSET_CURSOR;
BEGIN
 OPEN c_sqlarea_cursor FOR
   SELECT VALUE(p)
   FROM   TABLE( 
            DBMS_SQLTUNE.SELECT_CURSOR_CACHE(
            ' parsing_schema_name = ''ADHOC'' AND sql_text like ''%SPM_DEMO%'' ')
          ) p;
-- load the tuning set
  DBMS_SQLTUNE.LOAD_SQLSET (  
    sqlset_name     => 'my_workload'
,   populate_cursor =>  c_sqlarea_cursor 
);
END;
/

COLUMN SQL_TEXT FORMAT a30   
COLUMN SCH FORMAT a3
COLUMN ELAPSED FORMAT 999999999

column sql_text format a80
set pagesize 1000
SELECT SQL_ID, SQL_TEXT, 
       ELAPSED_TIME AS "ELAPSED", BUFFER_GETS
FROM   TABLE( DBMS_SQLTUNE.SELECT_SQLSET( 'my_workload' ) ) ;
