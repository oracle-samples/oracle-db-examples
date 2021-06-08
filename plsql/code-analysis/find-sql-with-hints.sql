/*
As of 12.2, PL/Scope now analyzes the static SQL statements that 
appear in your PL/SQL program units. It allows you to answer with ease 
questions like "Where do I use hints in my SQL statements?" 

Doc: http://docs.oracle.com/database/122/ADFNS/plscope.htm#ADFNS022
*/

ALTER SESSION SET plscope_settings='identifiers:all, statements:all';

CREATE OR REPLACE PROCEDURE proc1
IS
   l_id   INTEGER;
BEGIN
   SELECT /*+ result_cache */
          employee_id
     INTO l_id
     FROM hr.employees
    WHERE last_name = 'KING';
END;
/

CREATE OR REPLACE PROCEDURE proc2
IS
   TYPE nt IS TABLE OF INTEGER;

   l_ids   nt;
BEGIN
   SELECT /*+ FIRST_ROWS(10) */
          employee_id
     BULK COLLECT INTO l_ids
     FROM hr.employees;
END;
/

CREATE OR REPLACE PROCEDURE proc3
IS
   TYPE nt IS TABLE OF INTEGER;

   l_ids   nt;
BEGIN
   SELECT employee_id
     BULK COLLECT INTO l_ids
     FROM hr.employees;
END;
/

-- Does the statement have a hint?
-- What could be simpler?
SELECT object_name, 
       line, 
       full_text 
  FROM user_statements 
 WHERE has_hint = 'YES';

