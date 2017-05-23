/*
Oracle will never create pre-defined exceptions for all the ORA errors. 
So if you need to trap one of these in your code, create your OWN named exception and associate 
it to the desired error code with the EXCEPTION_INIT pragma. Then you can angle it by name.
*/

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

/*
Both SAVE EXCEPTIONS and LOG ERRORS record error codes as unsigned integers. 
But SQLERRM and this pragma definitely believe that an Oracle error code is negative.
*/

DECLARE  
   my_exception   EXCEPTION;  
   PRAGMA EXCEPTION_INIT (my_exception, 1830);  
BEGIN  
   RAISE my_exception;  
END; 
/

/*
The NO_DATA_FOUND error actually has two numbers associated with it: 100 (ANSI standard) and -1403 (Oracle error). 
You can't associate an exception with -1403. Only 100. Not sure why you'd want to anyway.
*/

DECLARE  
   my_exception   EXCEPTION;  
   PRAGMA EXCEPTION_INIT (my_exception, -1403);  
BEGIN  
   RAISE my_exception;  
END; 
/

DECLARE  
   my_exception   EXCEPTION;  
   PRAGMA EXCEPTION_INIT (my_exception, 100);  
BEGIN  
   RAISE my_exception;  
END; 
/

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

CREATE TABLE employees AS SELECT * FROM hr.employees 
/

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

CREATE OR REPLACE PACKAGE app_errs_pkg 
IS 
   failure_in_forall   EXCEPTION; 
   PRAGMA EXCEPTION_INIT (failure_in_forall, -24381); 
END; 
/

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
