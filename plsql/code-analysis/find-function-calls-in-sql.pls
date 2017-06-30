/*
   You can call your own (user-defined) functions in SQL. But you need to do so with care:
      * possible performance impact, due to context switches
      * possible read consistency issues, since SQL in a function called from SQL does not participate in "outer" SQL read consistency
*/

ALTER SESSION SET plscope_settings='identifiers:all, statements:all'
/

DROP TABLE my_data
/

CREATE TABLE my_data (n NUMBER)
/

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

/* Run this query to see the full hierarchy of identifiers/statements */

WITH one_obj_name AS (SELECT 'MY_PROCEDURE' object_name FROM DUAL)
    SELECT plscope_type,
           usage_id,
           usage_context_id,
           LPAD (' ', 2 * (LEVEL - 1)) || usage || ' ' || name usages
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
             WHERE st.object_name = one_obj_name.object_name)
START WITH usage_context_id = 0
CONNECT BY PRIOR usage_id = usage_context_id
/

/*
ST    7    2        SELECT - STATEMENT
ID    8    7          REFERENCE - TABLE MY_DATA
ID    9    7          REFERENCE - COLUMN N
ID    10    7          REFERENCE - FORMAL IN N_IN
ID    11    7          REFERENCE - COLUMN N
ID    13    7          CALL - FUNCTION MY_FUNCTION1
ID    14    7          CALL - FUNCTION MY_FUNCTION2
ID    15    7          ASSIGNMENT - VARIABLE L_MY_DATA
ID    16    15            CALL - FUNCTION MY_FUNCTION1
*/

/* Now what I want to do is return a list of all SQL statements
   that contain within it a call to a function */

WITH my_prog_unit AS (SELECT USER owner, 'MY_PROCEDURE' object_name FROM DUAL),
     full_set
     AS (SELECT ai.usage,
                ai.usage_id,
                ai.usage_context_id,
                ai.TYPE,
                ai.name
           FROM all_identifiers ai, my_prog_unit
          WHERE     ai.object_name = my_prog_unit.object_name
                AND ai.owner = my_prog_unit.owner
         UNION ALL
         SELECT st.TYPE,
                st.usage_id,
                st.usage_context_id,
                'type',
                'name'
           FROM all_statements st, my_prog_unit
          WHERE     st.object_name = my_prog_unit.object_name
                AND st.owner = my_prog_unit.owner),
     dml_statements
     AS (SELECT st.owner,
                st.object_name,
                st.line,
                st.usage_id,
                st.TYPE
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
/

/* Across all program units, all schemas */

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
/
