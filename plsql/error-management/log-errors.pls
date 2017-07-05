/*

LOG ERRORS allows you to suppress row-level errors in a single DML statement. 
Usually DML statements are atomic: either all rows are modified or none are.
LOG ERRORS lets you continue past a row-level error, in the meantime writing
information about that error to your error log table.

More information available here:
http://docs.oracle.com/database/121/ARPLS/d_errlog.htm#ARPLS680

LiveSQL script here:
https://livesql.oracle.com/apex/livesql/file/content_CTMX9U1B173HA6PZZN9B6JK3T.html

*/

/* Assumption: you have already created the EMPLOYEES table */

/* Now create an error log table for failed DML operations */

BEGIN
   DBMS_ERRLOG.create_error_log (dml_table_name => 'EMPLOYEES');
END;
/

/* There are five error-related columns (starting with ORA_ERR*)
   and then a column for each VARCHAR2-compatible column in the
   DML table.
*/

  SELECT column_name, data_type, data_length
    FROM user_tab_columns
   WHERE table_name = 'ERR$_EMPLOYEES'
ORDER BY column_id
/

/* Output from Query:
"COLUMN_NAME"                 "DATA_TYPE"                   "DATA_LENGTH"                 
"ORA_ERR_NUMBER$"             "NUMBER"                      "22"                          
"ORA_ERR_MESG$"               "VARCHAR2"                    "2000"                        
"ORA_ERR_ROWID$"              "UROWID"                      "4000"                        
"ORA_ERR_OPTYP$"              "VARCHAR2"                    "2"                           
"ORA_ERR_TAG$"                "VARCHAR2"                    "2000"                        
"EMPLOYEE_ID"                 "VARCHAR2"                    "4000"                        
"FIRST_NAME"                  "VARCHAR2"                    "4000"                        
"LAST_NAME"                   "VARCHAR2"                    "4000"                        
"EMAIL"                       "VARCHAR2"                    "4000"                        
"PHONE_NUMBER"                "VARCHAR2"                    "4000"                        
"HIRE_DATE"                   "VARCHAR2"                    "4000"                        
"JOB_ID"                      "VARCHAR2"                    "4000"                        
"SALARY"                      "VARCHAR2"                    "4000"                        
"COMMISSION_PCT"              "VARCHAR2"                    "4000"                        
"MANAGER_ID"                  "VARCHAR2"                    "4000"                        
"DEPARTMENT_ID"               "VARCHAR2"                    "4000"                        
*/

/*
Now let's try to do an update with some bad data.
This will fail because multiplying salary by 200 will
generate some values that are too big to fit into the 
column. 

First, without LOG ERRORS....which means the DML is 
"all or nothing" - no rows are updated if any one row
fails to update.
*/

DECLARE
   l_count   PLS_INTEGER;
BEGIN
   SELECT COUNT (*)
     INTO l_count
     FROM employees
    WHERE salary > 24000;

   DBMS_OUTPUT.put_line ('Before ' || l_count);

   UPDATE employees
      SET salary = salary * 200;

   SELECT COUNT (*)
     INTO l_count
     FROM employees
    WHERE salary > 24000;
EXCEPTION
   WHEN OTHERS
   THEN
      DBMS_OUTPUT.put_line (DBMS_UTILITY.format_error_stack);

      SELECT COUNT (*)
        INTO l_count
        FROM employees
       WHERE salary > 24000;

      DBMS_OUTPUT.put_line ('After ' || l_count);
END;
/

/* Output from above block:

Before 0
ORA-01438: value larger than specified precision allowed for this column 
After 0

*/

/* And now with LOG ERRORS: specify unlimited # of errors, OK. */

DECLARE
   l_count   PLS_INTEGER;
BEGIN
   SELECT COUNT (*)
     INTO l_count
     FROM employees
    WHERE salary > 24000;

   DBMS_OUTPUT.put_line ('Before ' || l_count);

       UPDATE employees
          SET salary = salary * 200
   LOG ERRORS REJECT LIMIT UNLIMITED;

   DBMS_OUTPUT.put_line ('After - SQL%ROWCOUNT ' || SQL%ROWCOUNT);   
   
   SELECT COUNT ( * )   
     INTO l_count   
     FROM employees   
    WHERE salary > 24000;   
   
   DBMS_OUTPUT.put_line ('After - Count in Table ' || l_count);  

   ROLLBACK;
END;
/

/* Output after running above block with LOG ERRORS

Before 0
After 1 - SQL%ROWCOUNT 49
After 2 - Count in Table 49

*/

/*
When using LOG ERRORS, you *must* check the error log table
immediately after running your DML statement. No error will
be raised to indicate there was any problem.
*/

SELECT 'Number of errors = ' || COUNT (*) FROM err$_employees
/

/* Output:

Number of errors = 58

*/

SELECT ORA_ERR_MESG$, ORA_ERR_ROWID$, last_name 
  FROM err$_employees
/

/* Output from above query:

ORA_ERR_MESG$	ORA_ERR_ROWID$	LAST_NAME
ORA-01438: value larger than specified precision allowed for this column	AAAeupAAXAAAADDAA5	Sully
ORA-01438: value larger than specified precision allowed for this column	AAAeupAAXAAAADDAA6	McEwen
ORA-01438: value larger than specified precision allowed for this column	AAAeupAAXAAAADDAA7	Smith
ORA-01438: value larger than specified precision allowed for this column	AAAeupAAXAAAADDAA8	Doran
ORA-01438: value larger than specified precision allowed for this column	AAAeupAAXAAAADDAA9	Sewall
ORA-01438: value larger than specified precision allowed for this column	AAAeupAAXAAAADDAA+	Vishney
ORA-01438: value larger than specified precision allowed for this column	AAAeupAAXAAAADDAA/	Greene
ORA-01438: value larger than specified precision allowed for this column	AAAeupAAXAAAADDABA	Marvins
ORA-01438: value larger than specified precision allowed for this column	AAAeupAAXAAAADDABB	Lee

*/
