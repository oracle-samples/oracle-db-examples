/*
When a SQL statement executes a user-defined function, your users pay 
the price of a context switch, which can be expensive, especially if 
the function is called in the WHERE clause. Even worse, if that function 
itself contains a SQL statement, you can run into data consistency issues. 
Fortunately, you can use PL/Scope in 12.2 to find all the SQL statements 
in your PL/SQL code that call a user-defined function, and then analyze from there.
*/

ALTER SESSION SET plscope_settings='identifiers:all, statements:all';

CREATE TABLE my_data (n NUMBER);

CREATE OR REPLACE FUNCTION my_function1
   RETURN NUMBER
   AUTHID DEFINER
IS
BEGIN
   RETURN 1;
END;
/

CREATE OR REPLACE FUNCTION my_function2
   RETURN NUMBER
   AUTHID DEFINER
IS
BEGIN
   RETURN 1;
END;
/

CREATE OR REPLACE PROCEDURE my_procedure (n_in IN NUMBER)
   AUTHID DEFINER
IS
   l_my_data   my_data%ROWTYPE;
BEGIN
   SELECT my_function1 ()
     INTO l_my_data
     FROM my_data
    WHERE     n = n_in
          AND my_function2 () = 0
          AND n = (SELECT my_function1 () FROM DUAL);

   SELECT COUNT (*)
     INTO l_my_data
     FROM my_data
    WHERE n = n_in;

   UPDATE my_data
      SET n = my_function2 ()
    WHERE n = n_in;
END;
/

-- Show All Identifiers and Statements - ALL_* Version
-- This query unions together rows from ALL_IDENTIFIERS and ALL_STATEMENTS to provide 
-- a complete picture of your program unit. 
WITH one_obj_name AS (SELECT USER owner, 'MY_PROCEDURE' object_name FROM DUAL) 
    SELECT plscope_type, 
           usage_id, 
           usage_context_id, 
           LPAD (' ', 2 * (LEVEL - 1)) || usage || ' ' || name usages, 
           line, 
           col, 
           signature 
      FROM (SELECT 'ID' plscope_type, 
                   ai.object_name, 
                   ai.usage usage, 
                   ai.usage_id, 
                   ai.usage_context_id, 
                   ai.TYPE || ' ' || ai.name name, 
                   ai.line, 
                   ai.col, 
                   signature 
              FROM all_identifiers ai, one_obj_name 
             WHERE ai.object_name = one_obj_name.object_name 
               AND ai.owner = one_obj_name.owner 
            UNION ALL 
            SELECT 'ST', 
                   st.object_name, 
                   st.TYPE, 
                   st.usage_id, 
                   st.usage_context_id, 
                   'STATEMENT', 
                   st.line, 
                   st.col, 
                   signature 
              FROM all_statements st, one_obj_name 
             WHERE st.object_name = one_obj_name.object_name 
               AND st.owner = one_obj_name.owner) 
START WITH usage_context_id = 0 
CONNECT BY PRIOR usage_id = usage_context_id


-- Show All Identifiers and Statements - USER_* Version
WITH one_obj_name AS (SELECT 'MY_PROCEDURE' object_name FROM DUAL) 
    SELECT plscope_type, 
           usage_id, 
           usage_context_id, 
           LPAD (' ', 2 * (LEVEL - 1)) || usage || ' ' || name usages, 
           line, 
           col, 
           signature 
      FROM (SELECT 'ID' plscope_type, 
                   ai.object_name, 
                   ai.usage usage, 
                   ai.usage_id, 
                   ai.usage_context_id, 
                   ai.TYPE || ' ' || ai.name name, 
                   ai.line, 
                   ai.col, 
                   signature 
              FROM user_identifiers ai, one_obj_name 
             WHERE ai.object_name = one_obj_name.object_name 
            UNION ALL 
            SELECT 'ST', 
                   st.object_name, 
                   st.TYPE, 
                   st.usage_id, 
                   st.usage_context_id, 
                   'STATEMENT', 
                   st.line, 
                   st.col, 
                   signature 
              FROM user_statements st, one_obj_name 
             WHERE st.object_name = one_obj_name.object_name) 
START WITH usage_context_id = 0 
CONNECT BY PRIOR usage_id = usage_context_id


-- Find SQL Statements Containing Function Calls - ALL_* Version
/*
Here's the secret sauce. I use subquery refactoring (WITH clause) to create 
and then use some data sets: my_prog_unit - specify the program unit of interest 
just once; full_set - the full set of statements and identifiers; dml_statements - 
the SQL DML statements in the program unit. Then I find all the DML statements 
whose full_set tree below it contain a call to a function.
*/

WITH my_prog_unit AS (SELECT USER owner, 'MY_PROCEDURE' object_name FROM DUAL), 
     full_set 
     AS (SELECT ai.usage, 
                ai.usage_id, 
                ai.usage_context_id, 
                ai.TYPE, 
                ai.name 
           FROM all_identifiers ai, my_prog_unit 
          WHERE ai.object_name = my_prog_unit.object_name 
            AND ai.owner = my_prog_unit.owner 
         UNION ALL 
         SELECT st.TYPE, 
                st.usage_id, 
                st.usage_context_id, 
                'type', 
                'name' 
           FROM all_statements st, my_prog_unit 
          WHERE st.object_name = my_prog_unit.object_name 
            AND st.owner = my_prog_unit.owner), 
     dml_statements 
     AS (SELECT st.owner, st.object_name, st.line, st.usage_id, st.type 
           FROM all_statements st, my_prog_unit 
          WHERE     st.object_name = my_prog_unit.object_name 
                AND st.owner = my_prog_unit.owner 
                AND st.TYPE IN ('SELECT', 'UPDATE', 'DELETE')) 
SELECT st.owner, 
       st.object_name, 
       st.line, 
       st.TYPE, 
       s.text 
  FROM dml_statements st, all_source s 
 WHERE     ('CALL', 'FUNCTION') IN (    SELECT fs.usage, fs.TYPE 
                                          FROM full_set fs 
                                    CONNECT BY PRIOR fs.usage_id = 
                                                  fs.usage_context_id 
                                    START WITH fs.usage_id = st.usage_id) 
       AND st.line = s.line 
       AND st.object_name = s.name 
       AND st.owner = s.owner


-- Find SQL Statements Containing Function Calls - USER_* Version
WITH my_prog_unit AS (SELECT 'MY_PROCEDURE' object_name FROM DUAL), 
     full_set 
     AS (SELECT ai.usage, 
                ai.usage_id, 
                ai.usage_context_id, 
                ai.TYPE, 
                ai.name 
           FROM user_identifiers ai, my_prog_unit 
          WHERE ai.object_name = my_prog_unit.object_name 
            /* Only with ALL_* AND ai.owner = my_prog_unit.owner */ 
         UNION ALL 
         SELECT st.TYPE, 
                st.usage_id, 
                st.usage_context_id, 
                'type', 
                'name' 
           FROM user_statements st, my_prog_unit 
          WHERE st.object_name = my_prog_unit.object_name 
            /* Only with ALL_* AND st.owner = my_prog_unit.owner */), 
     dml_statements 
     AS (SELECT /* Only with ALL_* st.owner, */ st.object_name, st.line, st.usage_id, st.type 
           FROM user_statements st, my_prog_unit 
          WHERE     st.object_name = my_prog_unit.object_name 
                /* Only with ALL_* AND st.owner = my_prog_unit.owner */ 
                AND st.TYPE IN ('SELECT', 'UPDATE', 'DELETE')) 
SELECT /* Only with ALL_* st.owner, */ 
       st.object_name, 
       st.line, 
       st.TYPE, 
       s.text 
  FROM dml_statements st, all_source s 
 WHERE     ('CALL', 'FUNCTION') IN (    SELECT fs.usage, fs.TYPE 
                                          FROM full_set fs 
                                    CONNECT BY PRIOR fs.usage_id = 
                                                  fs.usage_context_id 
                                    START WITH fs.usage_id = st.usage_id) 
       AND st.line = s.line 
       /* Only with ALL_*  AND st.owner = s.owner */ 
       AND st.object_name = s.name


-- Across All Schemas, All Program Units
-- Using ALL_* views; will not run in LiveSQL. See next statement.
WITH full_set 
     AS (SELECT ai.owner, 
                ai.object_name, 
                ai.usage, 
                ai.usage_id, 
                ai.usage_context_id, 
                ai.TYPE, 
                ai.name 
           FROM all_identifiers ai 
         UNION ALL 
         SELECT st.owner, 
                st.object_name, 
                st.TYPE, 
                st.usage_id, 
                st.usage_context_id, 
                'type', 
                'name' 
           FROM all_statements st), 
     dml_statements 
     AS (SELECT st.owner, 
                st.object_name, 
                st.line, 
                st.usage_id, 
                st.TYPE 
           FROM all_statements st 
          WHERE st.TYPE IN ('SELECT', 'UPDATE', 'DELETE')) 
SELECT st.owner, 
       st.object_name, 
       st.line, 
       st.TYPE, 
       s.text 
  FROM dml_statements st, all_source s 
 WHERE     ('CALL', 'FUNCTION') IN (    SELECT fs.usage, fs.TYPE 
                                          FROM full_set fs 
                                    CONNECT BY PRIOR fs.usage_id = 
                                                  fs.usage_context_id 
                                    START WITH fs.usage_id = st.usage_id) 
       AND st.line = s.line 
       AND st.object_name = s.name 
       AND st.owner = s.owner


-- Across All Program Units in Your Schema
-- Using USER_* views
WITH full_set 
     AS (SELECT ai.object_name, 
                ai.usage, 
                ai.usage_id, 
                ai.usage_context_id, 
                ai.TYPE, 
                ai.name 
           FROM user_identifiers ai 
         UNION ALL 
         SELECT st.object_name, 
                st.TYPE, 
                st.usage_id, 
                st.usage_context_id, 
                'type', 
                'name' 
           FROM user_statements st), 
     dml_statements 
     AS (SELECT st.object_name, 
                st.line, 
                st.usage_id, 
                st.TYPE 
           FROM user_statements st 
          WHERE st.TYPE IN ('SELECT', 'UPDATE', 'DELETE')) 
SELECT st.object_name, 
       st.line, 
       st.TYPE, 
       s.text 
  FROM user_statements st, user_source s 
 WHERE     ('CALL', 'FUNCTION') IN (    SELECT fs.usage, fs.TYPE 
                                          FROM full_set fs 
                                    CONNECT BY PRIOR fs.usage_id = 
                                                  fs.usage_context_id 
                                    START WITH fs.usage_id = st.usage_id) 
       AND st.line = s.line 
       AND st.object_name = s.name


