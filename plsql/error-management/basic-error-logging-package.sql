/*
This very, VERY basic error logging package demonstrations the critical elements: use an autonomous 
transaction to write a row to the error log; call the full suite of error-related built-in functions 
to gather all generic information; pass in application-specific data for logging.
*/

-- Error Logging Table
CREATE TABLE error_log 
( 
   log_id       NUMBER GENERATED ALWAYS AS IDENTITY, 
   created_on   TIMESTAMP WITH LOCAL TIME ZONE, 
   created_by   VARCHAR2 (100), 
   errorcode    INTEGER, 
   callstack    VARCHAR2 (4000), 
   errorstack   VARCHAR2 (4000), 
   backtrace    VARCHAR2 (4000), 
   error_info   VARCHAR2 (4000) 
);

-- Totally Minimal API for Error Logging
-- Including an example of providing a name for an un-named system exception 
-- raised when a FORALL with SAVE EXCEPTIONS encounters at least one failed statement.
CREATE OR REPLACE PACKAGE error_mgr 
IS 
   failure_in_forall   EXCEPTION; 
 
   PRAGMA EXCEPTION_INIT (failure_in_forall, -24381); 
 
   PROCEDURE log_error (app_info_in IN VARCHAR2); 
END;
/

-- Log the Error!
-- Key points: it's an autonomous transaction, which means the row is inserted into the error 
-- log without also committing other unsaved changes in the session (likely part of a business 
-- transaction that is in trouble). Plus, I invoke the full set of built-in functions to gather 
-- system-level information and write to table. Finally, I add the application-specific information.

CREATE OR REPLACE PACKAGE BODY error_mgr 
IS 
   PROCEDURE log_error (app_info_in IN VARCHAR2) 
   IS 
      PRAGMA AUTONOMOUS_TRANSACTION; 
      /* Cannot call this function directly in SQL */ 
      c_code   CONSTANT INTEGER := SQLCODE; 
   BEGIN 
      INSERT INTO error_log (created_on, 
                             created_by, 
                             errorcode, 
                             callstack, 
                             errorstack, 
                             backtrace, 
                             error_info) 
           VALUES (SYSTIMESTAMP, 
                   USER, 
                   c_code, 
                   DBMS_UTILITY.format_call_stack, 
                   DBMS_UTILITY.format_error_stack, 
                   DBMS_UTILITY.format_error_backtrace, 
                   app_info_in); 
 
      COMMIT; 
   END; 
END;
/

-- Try it Out
DECLARE 
   l_company_id   INTEGER; 
BEGIN 
   IF l_company_id IS NULL 
   THEN 
      RAISE VALUE_ERROR; 
   END IF; 
EXCEPTION  
   WHEN OTHERS 
   THEN 
      error_mgr.log_error ('Company ID is NULL - not allowed.'); 
END;
/

SELECT backtrace, errorstack, callstack FROM error_log;

