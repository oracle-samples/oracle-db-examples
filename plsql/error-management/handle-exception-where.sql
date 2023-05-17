/*
Where should you handle an exception? In each subprogram? Only at the top-level 
subprogram or anonymous block? I suggest that including exception sections in many 
"deep" subprograms is critical if you want to capture your application state 
(values of local variables or parameters, contents of tables, etc.) at the 
time of the error. Note: all database objects start with "plch" indicating that this 
script was taken from the Oracle Dev Gym (formerly known as the PL/SQL Challenge): 

https://devgym.oracle.com
*/

-- Create "Scratchpad" Package
-- I include this package to demonstrate how you *could* use a "global" variable 
-- to hold the values of local variables in deeply nested subprogram calls, to then log at a higher level.
CREATE OR REPLACE PACKAGE plch_pkg 
IS 
   g_save_value   NUMBER; 
END;
/

-- Very Simple Error Logger
-- Regardless of how you implement it, you should have a generalized error logging 
-- procedure that all developers on the team can invoke. Normally it would be an 
-- autonomous transaction procedure and insert into a table! I encourage you check 
-- out the Logger utility at oraopensource.com.
CREATE OR REPLACE PROCEDURE plch_log_error ( 
   data_in   IN VARCHAR2) 
IS 
BEGIN 
   /* Can and SHOULD also call: 
      - DBMS_UTILITY.FORMAT_ERROR_STACK 
      - DBMS_UTILITY.FORMAT_ERROR_BACKTRACE 
      - (12.1) UTL_CALL_STACK subprograms 
 
      But this gets the point across. 
   */ 
   DBMS_OUTPUT.put_line ( 
      SQLCODE || '-' || data_in); 
END;
/

-- Procedure with Local Variable
-- So, like many of your subprograms, my procedure has a parameter and a 
-- local variable. If something goes wrong in this procedure, I'd really like 
-- to know what the values of those elements are. After all, it is likely that 
-- they play a role in the error. So when I log the error, I pass the local 
-- variable. Then I re-raise to indicate to the invoking block that there is a problem.
CREATE OR REPLACE PROCEDURE plch_do_stuff ( 
   value_in   IN NUMBER) 
IS 
   l_value   NUMBER := value_in * 100; 
BEGIN 
   RAISE VALUE_ERROR; 
EXCEPTION 
   WHEN OTHERS 
   THEN 
      plch_log_error ('Value=' || l_value); 
      RAISE; 
END;
/

-- Verify Local Variable Value Accessible
-- Now I invoke my subprogram. Notice that I can see the value of my local variable. 
-- Excellent! So easy to diagnose the problem now. Or, at least, a little easier. :-)
BEGIN 
   plch_do_stuff (10); 
 
/* Note:  
   I include this exception handler so you can see the DBMS_OUTPUT text. 
   Otherwise, LiveSQL (currently) only displays the error that went unhanded.  
*/ 
EXCEPTION 
   WHEN OTHERS THEN NULL; 
END;
/

-- Procedure Saves State to Global Variable
-- Now let's take a look at a different approach. I do not log the error 
-- "locally" in my procedure. Instead, I copy the local value to a "global" 
-- in a package specification. Then I re-raise.
CREATE OR REPLACE PROCEDURE plch_do_stuff ( 
   value_in   IN NUMBER) 
IS 
   l_value   NUMBER := value_in * 100; 
BEGIN 
   RAISE VALUE_ERROR; 
EXCEPTION 
   WHEN OTHERS 
   THEN 
      plch_pkg.g_save_value := l_value; 
      RAISE; 
END;
/

-- Global Value Available in Invoking Block
-- Now at my higher-level block, I can trap the exception, and log the error, 
-- accessing my global value. This works, but it is not a dependable approach. 
-- What if A calls B calls C and: C fails and writes to plch_pkg.g_save_value, 
-- but then B also writes to plch_pkg.g_save_value, changing the value? 
-- By the time you get up to A, the value from C is lost. And then of course 
-- you get into issues like: should I declare a separate global for each data 
-- type? This approach is messy and best avoided.
BEGIN 
   plch_do_stuff (10); 
EXCEPTION 
   WHEN OTHERS 
   THEN 
      plch_log_error ('Value=' || plch_pkg.g_save_value); 
END;
/

-- No Local Exception Section
-- Now suppose I recompile my procedure - without any exception section at all. 
-- This is the approach suggested by others. Just have a single exception handler 
-- at the top level, trap any error there, and log whatever information you can. 
CREATE OR REPLACE PROCEDURE plch_do_stuff ( 
   value_in   IN NUMBER) 
IS 
   l_value   NUMBER := value_in * 100; 
BEGIN 
   RAISE VALUE_ERROR; 
END;
/

-- What Can I Log "Up" Here?
-- So now I trap the exception at the top level - but I have lost the 
-- plch_do_stuff.l_value variable's value. I can only log "generic" information 
-- about the state of my application through calls to DBMS_UTILITY functions or 
-- UTL_CALL_STACK (12.1). That's good information - critical - but often not enough.
BEGIN 
   plch_do_stuff (10); 
EXCEPTION 
   WHEN OTHERS 
   THEN 
      plch_log_error ('Value=?'); 
END;
/

