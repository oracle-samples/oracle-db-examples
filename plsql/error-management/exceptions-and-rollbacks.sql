/*
Any non-query DML statements that complete successfully in your session are 
not rolled back when an exception occurs - either directly in PL/SQL or 
propagated out from the SQL engine. You still have the option of either committing 
or rolling back yourself.

If, however, the exception goes unhandled out to the host environment, a rollback 
almost always occurs (this is performed by the host environment).
*/

CREATE TABLE employees
AS
   SELECT * FROM hr.employees;

-- Impact of First DML Sticks Around
-- My first DML statement changes 107 rows. The second DML statement fails, 
-- but you will see in the COUNT after the failure that the rows are still changed.
DECLARE
   l_count   PLS_INTEGER;
BEGIN
   SELECT COUNT (*)
     INTO l_count
     FROM employees
    WHERE salary = 10000;

   DBMS_OUTPUT.put_line ('Count=' || l_count);

   /* No problem here. */
   UPDATE employees
      SET salary = 10000;

   BEGIN
      UPDATE employees
         SET last_name = RPAD (last_name, 10000, '*');
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line (SQLERRM);
   END;

   SELECT COUNT (*)
     INTO l_count
     FROM employees
    WHERE salary = 10000;

   DBMS_OUTPUT.put_line ('Count=' || l_count);
END;
/

