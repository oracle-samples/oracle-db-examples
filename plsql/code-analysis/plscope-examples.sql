/*

PL/Scope is a powerful code analysis tool, built into PL/SQL. 
Before compiling your program units, turn it on with this statement: 

ALTER SESSION SET plscope_settings='identifiers:all'. 

Then you can query the ALL/USER_IDENTIFIERS views to get all sorts of 
great information about your code!
*/

-- Turn on PL/Scope
ALTER SESSION SET plscope_settings='identifiers:all' ;

-- Create Program Units to Analyze
CREATE OR REPLACE PACKAGE plscope_demo   
IS 
   PROCEDURE my_procedure (param1_in IN INTEGER   
                         , param2    IN employees.last_name%TYPE   
                          );   
END plscope_demo; 
/

CREATE OR REPLACE PACKAGE BODY plscope_demo 
IS 
   PROCEDURE my_procedure (param1_in IN INTEGER 
                         , param2    IN employees.last_name%TYPE 
                          ) 
   IS 
      c_no_such   CONSTANT NUMBER := 100; 
      l_local_variable     NUMBER; 
   BEGIN 
      IF param1_in > l_local_variable 
      THEN 
         DBMS_OUTPUT.put_line (param2); 
      ELSE 
         DBMS_OUTPUT.put_line (c_no_such); 
      END IF; 
   END my_procedure; 
END plscope_demo; 
/

-- Show Hierarchy of Identifier References
-- Use the USAGE_ID and USAGE_CONTEXT_ID columns, along with the incredibly 
-- useful CONNECT BY syntax, to show the hierarchy of identifier references. 
WITH plscope_hierarchy  
        AS (SELECT line  
                 , col  
                 , name  
                 , TYPE  
                 , usage  
                 , usage_id  
                 , usage_context_id  
              FROM user_identifiers  
             WHERE     object_name = 'PLSCOPE_DEMO'  
                   AND object_type = 'PACKAGE BODY')  
SELECT    LPAD (' ', 3 * (LEVEL - 1))  
       || TYPE  
       || ' '  
       || name  
       || ' ('  
       || usage  
       || ')'  
          identifier_hierarchy  
  FROM plscope_hierarchy  
START WITH usage_context_id = 0  
CONNECT BY PRIOR usage_id = usage_context_id  
ORDER SIBLINGS BY line, col 


-- Create Program Units to Analyze
CREATE OR REPLACE PACKAGE plscope_demo   
IS   
   public_global NUMBER; 
   
   PROCEDURE my_procedure (param1_in IN INTEGER, param2 IN DATE);   
   
   FUNCTION my_function (param1    IN INTEGER   
                       , in_param2 IN DATE   
                       , param3_in IN employees.last_name%TYPE   
                        )   
      RETURN VARCHAR2;   
END plscope_demo; 
/

-- Use PL/Scope to Check Naming Convention Violations
/*
A really nice application of this feature! For example, I use the convention 
that IN parameters end with "_in", OUT with "_out", etc. No, you don't have 
to LIKE my conventions; just recognize that if you have a consistent pattern you 
want to enforce and you can express that pattern in SQL, PL/Scope can identify violations!
*/

SELECT prog.name subprogram, parm.name parameter  
  FROM user_identifiers parm, user_identifiers prog  
 WHERE     parm.object_name = 'PLSCOPE_DEMO'  
       AND parm.object_type = 'PACKAGE'  
       AND prog.object_name = parm.object_name  
       AND prog.object_type = parm.object_type  
       AND parm.usage_context_id = prog.usage_id  
       AND parm.TYPE IN ('FORMAL IN', 'FORMAL IN OUT', 'FORMAL OUT')  
       AND parm.usage = 'DECLARATION'  
       AND ( (parm.TYPE = 'FORMAL IN'  
              AND LOWER (parm.name) NOT LIKE '%\_in' ESCAPE '\')  
            OR (parm.TYPE = 'FORMAL OUT'  
                AND LOWER (parm.name) NOT LIKE '%\_out' ESCAPE '\')  
            OR (parm.TYPE = 'FORMAL IN OUT'  
                AND LOWER (parm.name) NOT LIKE '%\_io' ESCAPE '\'))  
ORDER BY prog.name, parm.name ;

-- Create Program Unit to Analyze
CREATE OR REPLACE PROCEDURE plscope_demo_proc  
IS  
   plscope_demo_proc   NUMBER;  
BEGIN  
   DECLARE  
      plscope_demo_proc   EXCEPTION;  
   BEGIN  
      RAISE plscope_demo_proc;  
   END;  
  
   plscope_demo_proc := 1;  
END plscope_demo_proc; 
/

SELECT line  
     , name  
     , TYPE  
     , usage  
     , signature  
  FROM user_identifiers  
 WHERE     object_name = 'PLSCOPE_DEMO_PROC'  
       AND name = 'PLSCOPE_DEMO_PROC'  
ORDER BY line ;

-- Find usages of variable declared with given name
SELECT usg.line, usg.TYPE, usg.usage  
  FROM user_identifiers dcl, user_identifiers usg  
 WHERE     dcl.object_name = 'PLSCOPE_DEMO_PROC'  
       AND dcl.name = 'PLSCOPE_DEMO_PROC'  
       AND dcl.usage = 'DECLARATION'  
       AND dcl.TYPE = 'VARIABLE'  
       AND usg.signature = dcl.signature  
       AND usg.usage <> 'DECLARATION'  
ORDER BY line ;

-- Create Program Unit to Analyze
CREATE OR REPLACE PROCEDURE plscope_demo_proc  
IS  
   e_bad_data   EXCEPTION;  
   PRAGMA EXCEPTION_INIT (e_bad_data, -20900);  
BEGIN  
   RAISE e_bad_data;  
EXCEPTION  
   WHEN e_bad_data  
   THEN  
      DBMS_OUTPUT.PUT_LINE ('Report error!'); 
      RAISE;  
END plscope_demo_proc; 
/

-- Show all usages of an exception
SELECT line  
     , TYPE  
     , usage  
     , signature  
  FROM user_identifiers  
 WHERE     object_name = 'PLSCOPE_DEMO_PROC'  
       AND name = 'E_BAD_DATA'  
ORDER BY line ;

CREATE OR REPLACE PROCEDURE plscope_demo_proc  
IS  
   e_bad_data   EXCEPTION;  
   PRAGMA EXCEPTION_INIT (e_bad_data, -20900);  
   e_bad_data2  EXCEPTION;  
BEGIN  
   RAISE e_bad_data2;  
EXCEPTION  
   WHEN e_bad_data2  
   THEN  
      DBMS_OUTPUT.PUT_LINE (DBMS_UTILITY.FORMAT_ERROR_STACK); -- log_error ();  
END plscope_demo_proc; 
/

-- Identify programs with declared but not used exceptions
WITH subprograms_with_exception  
        AS (SELECT object_name  
                 , object_type  
                 , name  
              FROM user_identifiers has_exc  
             WHERE     has_exc.usage = 'DECLARATION'  
                   AND has_exc.TYPE = 'EXCEPTION'),  
     subprograms_with_raise_handle  
        AS (SELECT object_name  
                 , object_type  
                 , name  
              FROM user_identifiers with_rh  
             WHERE     with_rh.usage = 'REFERENCE'  
                   AND with_rh.TYPE = 'EXCEPTION')  
SELECT *  
  FROM subprograms_with_exception  
MINUS  
SELECT *  
  FROM subprograms_with_raise_handle 


-- Package-level variables in the specification
-- These are generally to be avoided - they are globals that can be changed 
-- by any session whose schema has execute authority on the package.
SELECT object_name, name, line  
  FROM user_identifiers ai  
 WHERE     ai.TYPE = 'VARIABLE'  
       AND ai.usage = 'DECLARATION'  
       AND ai.object_type = 'PACKAGE' ;

