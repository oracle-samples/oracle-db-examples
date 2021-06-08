/*
Oracle Database pre-defines a number of exceptions for common ORA errors, 
such as NO_DATA_FOUND and VALUE_ERROR. But there a whole lot more errors for 
which there is no pre-defined name. And some of these can be encountered quite 
often in code. The key thing for developers is to avoid hard-coding these error 
numbers in your code. Instead, use the EXCEPTION_INIT pragma to assign a name 
for that error code, and then handle it by name.
*/

-- Give a Name to an Unnamed Error
-- Oracle will never create pre-defined exceptions for all the ORA errors. 

So if you need to trap one of these in your code, create your OWN named exception and associate it to the desired error code with the EXCEPTION_INIT pragma. Then you can angle it by name.
DECLARE  
   e_bad_date_format   EXCEPTION;  
   PRAGMA EXCEPTION_INIT (e_bad_date_format, -1830);  
BEGIN  
   DBMS_OUTPUT.put_line (TO_DATE ('2010 10 10 44:55:66', 'YYYSS'));  
EXCEPTION  
   WHEN e_bad_date_format  
   THEN  
      DBMS_OUTPUT.put_line ('Bad date format');  
END; 
/

-- Pragma Expects a Negative Integer
-- Both SAVE EXCEPTIONS and LOG ERRORS record error codes as unsigned integers. 
-- But SQLERRM and this pragma definitely believe that an Oracle error code is negative.

DECLARE  
   my_exception   EXCEPTION;  
   PRAGMA EXCEPTION_INIT (my_exception, 1830);  
BEGIN  
   RAISE my_exception;  
END; 
/

-- Special Case: Can't EXCEPTION_INIT -1403
-- The NO_DATA_FOUND error actually has two numbers associated with it: 100 (ANSI standard) 
-- and -1403 (Oracle error). You can't associate an exception with -1403. Only 100. Not sure why you'd want to anyway.

DECLARE  
   my_exception   EXCEPTION;  
   PRAGMA EXCEPTION_INIT (my_exception, -1403);  
BEGIN  
   RAISE my_exception;  
END; 
/

-- This One Works
DECLARE  
   my_exception   EXCEPTION;  
   PRAGMA EXCEPTION_INIT (my_exception, 100);  
BEGIN  
   RAISE my_exception;  
END; 
/

-- Distinguish Between Different Application-Specific Errors
-- When you define your own exception, the error code is always by default set to 1 
-- and the error message is "User-defined exception". If you want to distinguish 
-- between those exceptions with SQLCODE, use the EXCEPTION_INIT pragma, and 
-- select your error code between -20999 and -20000. Once you do that, you will 
-- need to use RAISE_APPLICATION_ERROR to raise the exception, if you want to associate 
-- an error message with the error code.

DECLARE   
   e_bad_data         EXCEPTION;  
   
   e_bal_too_low      EXCEPTION;    
   PRAGMA EXCEPTION_INIT (e_bal_too_low, -20100);    
    
   e_account_closed   EXCEPTION;    
   en_account_closed  PLS_INTEGER := -20200;    
   PRAGMA EXCEPTION_INIT (e_account_closed, -20200);    
BEGIN    
   BEGIN    
      RAISE e_bad_data;    
   EXCEPTION    
      WHEN OTHERS    
      THEN    
         DBMS_OUTPUT.put_line (SQLCODE);    
         DBMS_OUTPUT.put_line (DBMS_UTILITY.format_error_stack);    
   END;    
  
   BEGIN    
      RAISE e_bal_too_low;    
   EXCEPTION    
      WHEN OTHERS    
      THEN    
         DBMS_OUTPUT.put_line (SQLCODE);    
         DBMS_OUTPUT.put_line (DBMS_UTILITY.format_error_stack);    
   END;    
    
   BEGIN    
      RAISE e_account_closed;    
   EXCEPTION    
      WHEN OTHERS    
      THEN    
         DBMS_OUTPUT.put_line (SQLCODE);    
         DBMS_OUTPUT.put_line (DBMS_UTILITY.format_error_stack);    
   END;     
    
   /* Now with RAISE_APPLICATION_ERROR */  
   BEGIN    
      RAISE_APPLICATION_ERROR (en_account_closed, 'Account has been closed.');    
   EXCEPTION    
      WHEN OTHERS    
      THEN    
         DBMS_OUTPUT.put_line (SQLCODE);    
         DBMS_OUTPUT.put_line (DBMS_UTILITY.format_error_stack);    
   END;    
END; 
/

CREATE TABLE employees AS SELECT * FROM hr.employees ;

-- The Bad Way: Hard-Coding the Error Code in Exception Section
-- The problem with writing code like WHEN OTHERS THEN IF SQLCODE = -24381 ..." 
-- is that Oracle might change the error code at some point. No, you can trust 
-- that -24381 will ALWAYS be the error code when a FORALL with SAVE EXCEPTIONS fails. 
-- The problem is that when you write code like this, you are saying to anyone coming 
-- along later: "Ha, ha! I know all about obscure Oracle error codes, and you don't." 
-- In other words, the code makes people who are responsible for maintaining feel stupid. 
-- It raises questions in their minds and makes them uncomfortable.

DECLARE 
   TYPE namelist_t IS TABLE OF VARCHAR2 (1000); 
 
   enames_with_errors   namelist_t 
      := namelist_t ('ABC', RPAD ('BIGBIGGERBIGGEST', 1000, 'ABC'), 'DEF'); 
BEGIN 
   FORALL indx IN 1 .. enames_with_errors.COUNT SAVE EXCEPTIONS 
      UPDATE employees 
         SET first_name = enames_with_errors (indx); 
EXCEPTION 
   WHEN OTHERS 
   THEN 
      IF SQLCODE = -24381 
      THEN 
         DBMS_OUTPUT.put_line (DBMS_UTILITY.format_error_stack); 
         DBMS_OUTPUT.put_line ( 
            'Number of failed statements = ' || SQL%BULK_EXCEPTIONS.COUNT); 
      ELSE 
         RAISE; 
      END IF; 
END; 
/

-- A Better Way to Go: Declare Exception
-- This is much better: I declare a local exception, associate it with -24381, then use 
-- that exception in the WHEN clause. The problem with this code is that the exception is 
-- declared locally, but I will/might use FORALL in many places in my code. 

DECLARE 
   failure_in_forall    EXCEPTION; 
   PRAGMA EXCEPTION_INIT (failure_in_forall, -24381); 
 
   TYPE namelist_t IS TABLE OF VARCHAR2 (1000); 
 
   enames_with_errors   namelist_t 
      := namelist_t ('ABC', RPAD ('BIGBIGGERBIGGEST', 1000, 'ABC'), 'DEF'); 
BEGIN 
   FORALL indx IN 1 .. enames_with_errors.COUNT SAVE EXCEPTIONS 
      UPDATE employees 
         SET first_name = enames_with_errors (indx); 
EXCEPTION 
   WHEN failure_in_forall 
   THEN 
      DBMS_OUTPUT.put_line (DBMS_UTILITY.format_error_stack); 
      DBMS_OUTPUT.put_line ( 
         'Number of failed statements = ' || SQL%BULK_EXCEPTIONS.COUNT); 
END; 
/

-- The Best Approach: Declare Exception in Package Specification
-- Now, any schema with EXECUTE authority on this package can reference the exception.
CREATE OR REPLACE PACKAGE app_errs_pkg 
IS 
   failure_in_forall   EXCEPTION; 
   PRAGMA EXCEPTION_INIT (failure_in_forall, -24381); 
END; 
/

-- No Need for Local Declaration of Exception
-- I just reference the exception as package.exception_name in my WHEN clause. Nice.
DECLARE 
   TYPE namelist_t IS TABLE OF VARCHAR2 (1000); 
 
   enames_with_errors   namelist_t 
      := namelist_t ('ABC', RPAD ('BIGBIGGERBIGGEST', 1000, 'ABC'), 'DEF'); 
BEGIN 
   FORALL indx IN 1 .. enames_with_errors.COUNT SAVE EXCEPTIONS 
      UPDATE employees 
         SET first_name = enames_with_errors (indx); 
EXCEPTION 
   WHEN app_errs_pkg.failure_in_forall 
   THEN 
      DBMS_OUTPUT.put_line (DBMS_UTILITY.format_error_stack); 
      DBMS_OUTPUT.put_line ( 
         'Number of failed statements = ' || SQL%BULK_EXCEPTIONS.COUNT); 
END; 
/

