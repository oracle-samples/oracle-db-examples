ALTER SESSION SET plscope_settings='identifiers:all, statements:all'
/

CREATE OR REPLACE PROCEDURE p1 (p_id NUMBER, p_name OUT VARCHAR2)
IS
BEGIN
   SELECT 
          last_name
     INTO 
          p_name
     FROM 
          employees
    WHERE    
          employee_id = p_id;
END;
/

CREATE OR REPLACE PROCEDURE p2 (id_in NUMBER, name_out OUT VARCHAR2)
IS
BEGIN
   SELECT last_name
     INTO name_out
     FROM EMPLOYEES
    WHERE employee_id = id_in;
END;
/

  SELECT signature, sql_id, text
    FROM all_statements
   WHERE object_name IN ('P1', 'P2')
ORDER BY line, col
/

/* Same SQL appearing more than once? */

  SELECT sql_id, text, COUNT (*)
    FROM all_statements
   WHERE sql_id IS NOT NULL
GROUP BY sql_id, text
  HAVING COUNT (*) > 1
/

SELECT owner,
       object_name,
       line,
       text
  FROM all_statements
 WHERE sql_id IN (  SELECT sql_id
                      FROM all_statements
                     WHERE sql_id IS NOT NULL
                  GROUP BY sql_id
                    HAVING COUNT (*) > 1)
 ORDER BY owner, object_name, line                    
/
