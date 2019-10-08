/*
The DBMS_UTILITY.format_error_backtrace function, added in Oracle Database 10g Release 2, 
is a critical subprogram to call when logging exceptions. It returns a string that traces 
the error back to the line on which it was raised! Note: if you re-raise an exception as 
it propagates up the stack, you will lose the "original" line number. The back trace function 
always only traces back to the most recently raised exception.
*/

CREATE OR REPLACE PROCEDURE proc1 
IS 
BEGIN 
   DBMS_OUTPUT.put_line ('running proc1'); 
   RAISE NO_DATA_FOUND; 
END; 
/

CREATE OR REPLACE PROCEDURE proc2 
IS 
   l_str   VARCHAR2 (30) := 'calling proc1'; 
BEGIN 
   DBMS_OUTPUT.put_line (l_str); 
   proc1; 
END; 
/

CREATE OR REPLACE PROCEDURE proc3 
IS 
BEGIN 
   DBMS_OUTPUT.put_line ('calling proc2'); 
   proc2; 
END; 
/

-- Without Back Trace....
-- The only way to "see" the line number on which the error was raised was to let the exception go unhandled.
BEGIN  
   DBMS_OUTPUT.put_line ('Proc3 -> Proc2 -> Proc1 unhandled');  
   proc3;  
END; 
/

-- Trap and Display Error Stack (Error Message)
-- Sure, that works fine and is very good info to have, but the error stack (error message) will contain the line number on which the error was raised!
BEGIN  
   DBMS_OUTPUT.put_line ('Proc3 -> Proc2 -> Proc1 unhandled');  
   proc3;  
EXCEPTION  
   WHEN OTHERS  
   THEN  
      DBMS_OUTPUT.put_line (DBMS_UTILITY.format_error_stack);  
END; 
/

-- Add Back Trace to Error Handler
-- Now we trap the exception at the top level subprogram and view both the error stack and the back trace.
CREATE OR REPLACE PROCEDURE proc3   
IS   
BEGIN   
   DBMS_OUTPUT.put_line ('calling proc2');   
   proc2;   
EXCEPTION   
   WHEN OTHERS   
   THEN   
      DBMS_OUTPUT.put_line ('Error backtrace at top level:');   
      DBMS_OUTPUT.put_line (DBMS_UTILITY.format_error_stack);   
      DBMS_OUTPUT.put_line (DBMS_UTILITY.format_error_backtrace);   
END; 
/

BEGIN 
   DBMS_OUTPUT.put_line ('Proc3 -> Proc2 -> Proc1 backtrace'); 
   proc3; 
END; 
/

-- Re-Raise Exception
-- I show the back trace, but then re-raise.
CREATE OR REPLACE PROCEDURE proc1   
IS   
BEGIN   
   DBMS_OUTPUT.put_line ('running proc1');   
   RAISE NO_DATA_FOUND;   
EXCEPTION   
   WHEN OTHERS   
   THEN   
      DBMS_OUTPUT.put_line ('Error backtrace in block where raised:');   
      DBMS_OUTPUT.put_line (DBMS_UTILITY.format_error_backtrace);   
      RAISE;   
END; 
/

-- Can't Trace All the Way Back
-- The call to back trace in this upper-level subprogram no longer finds it way back to the line number of the original exception. That was wiped out with the call to RAISE;
CREATE OR REPLACE PROCEDURE proc3   
IS   
BEGIN   
   DBMS_OUTPUT.put_line ('calling proc2');   
   proc2;   
EXCEPTION   
   WHEN OTHERS   
   THEN   
      DBMS_OUTPUT.put_line ('Error backtrace at top level:');   
      DBMS_OUTPUT.put_line (DBMS_UTILITY.format_error_backtrace);   
END; 
/

BEGIN 
   DBMS_OUTPUT.put_line ('Proc3 -> Proc2 -> Proc1, re-reraise in Proc1'); 
   proc3; 
END; 
/

-- Handle and Raise At Every Level
-- And see how the back trace changes!
CREATE OR REPLACE PROCEDURE proc1  
IS  
BEGIN  
   DBMS_OUTPUT.put_line ('running proc1');  
   RAISE NO_DATA_FOUND;  
EXCEPTION  
   WHEN OTHERS  
   THEN  
      DBMS_OUTPUT.put_line ('Error stack in block where raised:');  
      DBMS_OUTPUT.put_line (DBMS_UTILITY.format_error_backtrace);  
      RAISE;  
END; 
/

CREATE OR REPLACE PROCEDURE proc2 
IS 
BEGIN 
   DBMS_OUTPUT.put_line ('calling proc1'); 
   proc1; 
EXCEPTION 
   WHEN OTHERS 
   THEN 
      RAISE VALUE_ERROR; 
END; 
/

CREATE OR REPLACE PROCEDURE proc3  
IS  
BEGIN  
   DBMS_OUTPUT.put_line ('calling proc2');  
   proc2;  
EXCEPTION  
   WHEN OTHERS  
   THEN  
      DBMS_OUTPUT.put_line ('Error backtrace at top level:');  
      DBMS_OUTPUT.put_line (DBMS_UTILITY.format_error_backtrace);  
END; 
/

BEGIN 
   DBMS_OUTPUT.put_line 
           ('Proc3 -> Proc2 -> Proc1, re-reraise in Proc1, raise VE in Proc2'); 
   proc3; 
END; 
/
