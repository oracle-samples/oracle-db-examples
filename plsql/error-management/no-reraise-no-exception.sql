/*
You have a subprogram that invokes another subprogram (or nested block). 
That "inner" subprogram fails with an exception. It contains an exception handler. 
It logs the error, but then neglects to re-raise that exception (or another). 
Control passes out to the invoking subprogram, and it continues executing statements, 
completely unaware that an error occurred in that inner block. Which means, 
by the way, that a call to SQLCODE will return 0. This may be just what 
you want, but make sure you do this deliberately.

-- SQLCODE Outside of Exception Section Always 0
-- Because outside of an exception section, there is no exception. You are either declaring or executing. 
BEGIN 
   DBMS_OUTPUT.put_line (SQLCODE); 
END;
/

-- SQLCODE Invoked via Nested Subprogram from Exception Section
-- Just to avoid any misunderstanding: in this block, SQLCODE is "written" 
-- outside of the exception section, but it is executed from within the OTHERS handler, 
-- so SQLCODE will properly show the non-zero error code.
DECLARE 
   PROCEDURE my_proc 
   IS 
   BEGIN 
      DBMS_OUTPUT.put_line ( 
            'Nested subprogram called from exception section SQLCODE=' 
         || SQLCODE); 
   END; 
BEGIN 
   RAISE NO_DATA_FOUND; 
EXCEPTION 
   WHEN OTHERS 
   THEN 
      my_proc; 
END; 
/

-- Watch the Changing SQLCODE Value
DECLARE 
   aname   VARCHAR2 (5); 
BEGIN 
   BEGIN 
      aname := 'Big String'; 
      DBMS_OUTPUT.put_line (aname); 
   EXCEPTION 
      WHEN VALUE_ERROR 
      THEN 
         DBMS_OUTPUT.put_line ( 
             'Inner block exception section SQLCODE='||SQLCODE); 
   END; 
 
   DBMS_OUTPUT.put_line ('In executable section SQLCODE='||SQLCODE); 
EXCEPTION 
   WHEN VALUE_ERROR 
   THEN 
      DBMS_OUTPUT.put_line ( 
          'Outer block exception section SQLCODE='||SQLCODE); 
END;
/

ALTER SESSION SET plsql_warnings = 'enable:all' ;

CREATE OR REPLACE PROCEDURE swallow_error AUTHID DEFINER 
IS  
   aname   VARCHAR2 (5);  
BEGIN  
   BEGIN  
      aname := 'Big';  
      DBMS_OUTPUT.put_line (aname);  
   EXCEPTION  
      WHEN OTHERS  
      THEN  
         DBMS_OUTPUT.put_line (  
             'Inner block exception section SQLCODE='||SQLCODE);  
   END;  
  
   DBMS_OUTPUT.put_line ('In executable section SQLCODE='||SQLCODE);  
EXCEPTION  
   WHEN VALUE_ERROR  
   THEN  
      DBMS_OUTPUT.put_line (  
          'Outer block exception section SQLCODE='||SQLCODE);  
END; 
/

SELECT text FROM USER_ERRORS 
 WHERE name = 'SWALLOW_ERROR'
/
 

