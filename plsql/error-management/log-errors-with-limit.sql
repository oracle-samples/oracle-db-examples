
/*
When you specify a limit for the LOG ERRORS clause, Oracle will terminate 
the execution of the DML statement when that number of errors have been raised. 
*/

-- Create and populate a table
-- The "plch" prefix indicates this code was taken from a PL/SQL Challenge quiz.
CREATE TABLE plch_parts 
( 
   partnum    NUMBER (3) PRIMARY KEY 
 , partname   VARCHAR2 (100) UNIQUE 
);

BEGIN
   INSERT INTO plch_parts
        VALUES (999, 'Mouse');

   INSERT INTO plch_parts
        VALUES (998, 'Keyboard');

   INSERT INTO plch_parts
        VALUES (997, 'Monitor');

   COMMIT;
END;
/

-- Create error logging table for parts table
-- If you want to use LOG ERRORS with a DML statement, you need to first create an error logging table.
BEGIN 
   DBMS_ERRLOG.create_error_log (dml_table_name => 'PLCH_PARTS'); 
END;
/

-- If I use UNLIMITED with REJECT LIMIT, then Oracle will (attempt to) modify 
-- every single row identified by the DML statement. Any problems? Write it to the error 
-- log table! When it is done? No exception will be raised!
DECLARE 
   l_count   PLS_INTEGER; 
BEGIN 
   SELECT COUNT (*) INTO l_count FROM err$_plch_parts; 
 
   DBMS_OUTPUT.put_line ('Before = ' || l_count); 
 
       UPDATE plch_parts 
          SET partnum = partnum * 10 
   LOG ERRORS REJECT LIMIT UNLIMITED; 
 
   SELECT COUNT (*) INTO l_count FROM err$_plch_parts; 
 
   DBMS_OUTPUT.put_line ('After = ' || l_count); 
END;
/

-- Impact of REJECT LIMIT clause (not UNLIMITED)
-- So suppose I am updating 1M rows. Normally, I would expect an error rate of no more 
-- than .1% - 1000 rows that might have problems. But if the number goes above that, 
-- something is badly wrong and I just want to stop the whole thing. In this case, 
-- I add an integer value after REJECT LIMIT. Now, Oracle will halt DML processing 
-- when the number of errors exceeds the specified limit. Plus, it will terminate with an error.
DECLARE 
   l_count   PLS_INTEGER; 
BEGIN 
   SELECT COUNT (*) INTO l_count FROM err$_plch_parts; 
 
   DBMS_OUTPUT.put_line ('Before = ' || l_count); 
 
       UPDATE plch_parts 
          SET partnum = partnum * 10 
   LOG ERRORS REJECT LIMIT 2; 
 
   SELECT COUNT (*) INTO l_count FROM err$_plch_parts; 
 
   DBMS_OUTPUT.put_line ('After = ' || l_count); 
EXCEPTION 
   WHEN OTHERS 
   THEN 
      DBMS_OUTPUT.put_line ('Error = ' || DBMS_UTILITY.FORMAT_ERROR_STACK); 
 
      SELECT COUNT (*) INTO l_count FROM err$_plch_parts; 
 
      DBMS_OUTPUT.put_line ('After Error = ' || l_count); 
END;
/

