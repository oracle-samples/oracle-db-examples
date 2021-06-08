/*
Add the LOG ERRORS clause to your non-query DML statement, and the SQL engine will 
continue executing the statement, even if changes to individual rows fail. Any failed
row changes are written to an error log table. Used in conjunction with the DBMS_ERRLOG 
package. DBMS_ERRLOG doc: http://docs.oracle.com/database/121/ARPLS/d_errlog.htm#ARPLS680
*/

-- Local Table to Modify
CREATE TABLE employees AS SELECT * FROM hr.employees;

-- Create the Error Log Table
-- This simple usage of the create_error_log procedure creates a table named ERR$_EMPLOYEES 
-- in my schema. Additional parameters allow me to specify my own name (clearly necessary 
-- if your original table name has > 25 characters and you are not yet on 12.2!) and a specific tablespace. 
-- You can also ask it to "skip" incompatible columns - the meaning of which is clear 
-- when we look at the columns in an error log table....
                                                              
BEGIN  
   DBMS_ERRLOG.create_error_log (dml_table_name => 'EMPLOYEES');  
END; 
/

-- Show Columns of Error Log Table
-- DBMS_ERRLOG creates a table that starts with five error-related columns: 
-- ORA_ERR_NUMBER$ (error code), ORA_ERR_MESG$ (error message), ORA_ERR_ROWID$, ORA_ERR_OPTYP$ 
-- (operation type - U, I, D), ORA_ERR_TAG$ (optional "tag" text you can provide in LOG ERRORS clause). 
-- Then it adds VARCHAR2(4000) columns for any column in DML table that is compatible with 
-- VARCHAR2. Example: DATE works, but CLOB does not.
SELECT column_name, data_type 
  FROM user_tab_columns 
 WHERE table_name = 'ERR$_EMPLOYEES' 
ORDER BY COLUMN_ID;

-- All or Nothing - Without LOG ERRORS
-- This step shows you how the results of a DML statement are usually "all or nothing" 
-- either all rows specified by the DML statement are changed successfully, or none are. 
-- That is, if N rows are modified, but then the N+1 row causes an error, the changes 
-- to the previous N rows are rolled back. So the number of people making a salary > 24000 
-- is 0, both before and after the UPDATE, since at least one person's salary, 
-- when multiplied by 200, exceeds the constraint on the salary column.
DECLARE  
   l_count   PLS_INTEGER;  
BEGIN  
   SELECT COUNT ( * )  
     INTO l_count  
     FROM employees  
    WHERE salary > 24000;  
  
   DBMS_OUTPUT.put_line ('Before ' || l_count);  
  
   UPDATE employees  
      SET salary = salary * 200;  
  
   SELECT COUNT ( * )  
     INTO l_count  
     FROM employees  
    WHERE salary > 24000;  
EXCEPTION  
   WHEN OTHERS  
   THEN  
      DBMS_OUTPUT.put_line (DBMS_UTILITY.format_error_stack);  
  
      SELECT COUNT ( * )  
        INTO l_count  
        FROM employees  
       WHERE salary > 24000;  
  
      DBMS_OUTPUT.put_line ('After ' || l_count);  
END; 
/

-- Suppressing Row-Level Errors
-- Now I run the script again, with LOG ERRORS added, also specifying that I don't 
-- care how many errors occur - just keeping going. The net result is that of the 107 
-- rows in the employees table, 49 are updated, while 58 have errors. Nice!
DECLARE   
   l_count   PLS_INTEGER;   
BEGIN   
   SELECT COUNT ( * )   
     INTO l_count   
     FROM employees   
    WHERE salary > 24000;   
   
   DBMS_OUTPUT.put_line ('Before ' || l_count);   
   
       UPDATE employees   
          SET salary = salary * 200   
LOG ERRORS  INTO ERR$_EMPLOYEES (substr (last_name, 1, 20)) REJECT LIMIT UNLIMITED;    
   
   DBMS_OUTPUT.put_line ('After - SQL%ROWCOUNT ' || SQL%ROWCOUNT);    
    
   SELECT COUNT ( * )    
     INTO l_count    
     FROM employees    
    WHERE salary > 24000;    
    
   DBMS_OUTPUT.put_line ('After - Count in Table ' || l_count);   
   
   ROLLBACK;   
END; 
/

SELECT COUNT ( * ) "Number of Failures" 
  FROM err$_employees ;

-- Check the Error Log Table!
-- When you use LOG ERRORS, it is absolutely critical that you check the table 
-- immediately after the DML statement for errors from that statement. The SQL statement 
-- does not terminate with an exception, so looking at the table is THE ONLY WAY to know 
-- if anything went wrong! A common action at this point is to move the error information 
-- from your table-specific DML error log table to a persistent application error log table.
SELECT ora_err_number$, ora_err_mesg$, ora_err_rowid$, ora_err_tag$, last_name   
  FROM err$_employees   
 WHERE ROWNUM < 10 ;

-- Clean Up the Error Log Table
-- After checking the contents, I clean out the table, so the contents do not confuse 
-- me when I execute the next DML statement on the table.
BEGIN  
   DELETE FROM err$_employees;  
  
   COMMIT;  
END; 
/

-- Specify Limit on Rejections (Errors)
-- Suppose I am doing a bulk update, but I expect that very few errors will occur. 
-- If more than 10 row updates fail, something is wrong, and I want to simply stop. 
--Then LOG ERRORS REJECT LIMIT 10 will do the trick.
BEGIN  
       UPDATE employees  
          SET first_name = first_name || first_name || first_name  
   LOG ERRORS REJECT LIMIT 10;  
  
   ROLLBACK;  
END; 
/

SELECT 'Number of errors = ' || COUNT ( * ) 
  FROM err$_employees ;

