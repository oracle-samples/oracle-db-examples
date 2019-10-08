/*
SQLERRM is a function that returns the current error message (if no argument is passed to it)
or the system error message associated with the specified error code. DBMS_UTILITY.FORMAT_ERROR_STACK 
also returns the error message (or stack, if there is a stack of errors) and avoids truncation issues 
that may occur with SQLERRM.
*/

-- SQLERRM with No Arguments
BEGIN 
   RAISE TOO_MANY_ROWS; 
EXCEPTION 
   WHEN OTHERS 
   THEN 
      DBMS_OUTPUT.put_line (SQLERRM); 
END; 
/

-- SQLERRM as Lookup Function
BEGIN 
   DBMS_OUTPUT.put_line (SQLERRM (-1422)); 
END; 
/

-- That's Right: Oracle Errors are Negative
-- Even though some other parts of Oracle Database store error codes as unsigned integers (LOG ERRORS, SAVE EXCEPTIONS).
BEGIN 
   DBMS_OUTPUT.put_line (SQLERRM (1422)); 
END; 
/

-- Call Both Error Message Functions
-- And show the length of the string (useful when examining truncation issues in last step of script).
CREATE OR REPLACE PROCEDURE show_errors 
IS 
BEGIN 
   DBMS_OUTPUT.put_line ('-------SQLERRM-------------'); 
   DBMS_OUTPUT.put_line (SQLERRM); 
   DBMS_OUTPUT.put_line ('-------FORMAT_ERROR_STACK--'); 
   DBMS_OUTPUT.put_line (DBMS_UTILITY.format_error_stack); 
   DBMS_OUTPUT.put_line (' '); 
END;
/

CREATE OR REPLACE PROCEDURE proc1
IS
BEGIN
   RAISE NO_DATA_FOUND;
END;
/

CREATE OR REPLACE PACKAGE pkg1 
IS 
   PROCEDURE proc2; 
END pkg1;
/

CREATE OR REPLACE PACKAGE BODY pkg1 
IS 
   PROCEDURE proc2 
   IS 
   BEGIN 
      proc1; 
   EXCEPTION 
      WHEN OTHERS 
      THEN 
         RAISE DUP_VAL_ON_INDEX; 
   END; 
END pkg1;
/

-- Raise Application Error - and Keep the Stack
-- The third argument of raise_application_error determines whether or not the stack of errors is kept 
-- or discarded. TRUE = Keep.
CREATE OR REPLACE PROCEDURE proc3 
IS 
BEGIN 
   FOR indx IN 1 .. 1000 
   LOOP 
      NULL; 
   END LOOP; 
 
   pkg1.proc2; 
EXCEPTION 
   WHEN OTHERS 
   THEN 
      raise_application_error (-20000, 'TOP MOST ERROR MESSAGE', TRUE); 
END;
/

BEGIN
   proc3;
EXCEPTION
   WHEN OTHERS
   THEN
      show_errors;
END;
/

-- Now Discard Error Stack
CREATE OR REPLACE PROCEDURE proc3 
IS 
BEGIN 
   FOR indx IN 1 .. 1000 
   LOOP 
      NULL; 
   END LOOP; 
 
   pkg1.proc2; 
EXCEPTION 
   WHEN OTHERS 
   THEN 
      raise_application_error (-20000, 'TOP MOST ERROR MESSAGE', FALSE); 
END;
/

BEGIN
   proc3;
EXCEPTION
   WHEN OTHERS
   THEN
      show_errors;
END;
/

-- SQLERRM Can Truncate on Long Stacks
-- DBMS_UTILITY.format_error_stack? Not so much. And notice down at the bottom: the original exception.
DECLARE 
   PROCEDURE show_errors 
   IS 
   BEGIN 
      DBMS_OUTPUT.put_line ('-------SQLERRM-------------'); 
      DBMS_OUTPUT.put_line (LENGTH (SQLERRM)); 
      DBMS_OUTPUT.put_line (SQLERRM); 
      DBMS_OUTPUT.put_line ('-------FORMAT_ERROR_STACK--'); 
      DBMS_OUTPUT.put_line ( 
         LENGTH (DBMS_UTILITY.format_error_stack)); 
      DBMS_OUTPUT.put_line (DBMS_UTILITY.format_error_stack); 
   END; 
 
   PROCEDURE raise_error (nth_in IN INTEGER) 
   IS 
   BEGIN 
      IF nth_in <= 10000 
      THEN 
         raise_error (nth_in + 1); 
      ELSE 
         RAISE NO_DATA_FOUND; 
      END IF; 
   EXCEPTION 
      WHEN OTHERS 
      THEN 
         RAISE VALUE_ERROR; 
   END; 
BEGIN 
   raise_error (1); 
EXCEPTION 
   WHEN OTHERS 
   THEN 
      show_errors; 
END;
/

