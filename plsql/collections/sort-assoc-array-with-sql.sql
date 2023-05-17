/*
Starting with 12.1, you can apply the TABLE operators to associative arrays 
indexed by integer (index-by tables), whose types are declared in a package 
specification. You can then use the awesome power of SQL to sort the contents 
of the collection however you want.
*/

CREATE TABLE employees
AS
   SELECT * FROM hr.employees;

CREATE OR REPLACE PACKAGE my_arrays
IS
   TYPE employees_t IS TABLE OF employees%ROWTYPE
      INDEX BY PLS_INTEGER;
END;
/

-- If You Can Do It in SQL....
-- Once that collection is passed out of the TABLE operator, you can treat it 
-- just like any other relational table. Nice, huh?
DECLARE 
   l_employees   my_arrays.employees_t; 
BEGIN 
   DBMS_OUTPUT.PUT_LINE ('*********** Sort by Last Name'); 
 
   /* Fill the collection from the table to  
      get things started. But just to be clear: 
      the more common use case for this ordering 
      will be with data what was pushed into the 
      collection from a PL/SQL-based algorithm - 
      not in any order or not easily sorted in your 
      code. */ 
 
   SELECT * 
     BULK COLLECT INTO l_employees 
     FROM employees; 
 
   FOR emp IN (  SELECT * 
                   FROM TABLE (l_employees) 
                  WHERE department_id = 80 
               ORDER BY last_name) 
   LOOP 
      DBMS_OUTPUT.put_line ( 
         emp.department_id || '-' || emp.last_name); 
   END LOOP; 
 
   DBMS_OUTPUT.PUT_LINE ('*********** Sort by Hire Date'); 
 
   FOR emp IN (  SELECT * 
                   FROM TABLE (l_employees) 
                  WHERE last_name LIKE '%e%' 
               ORDER BY hire_date DESC) 
   LOOP 
      DBMS_OUTPUT.put_line ( 
         TO_CHAR (emp.hire_date) || '-' || emp.last_name); 
   END LOOP; 
END;
/

-- Replace Contents of Collection with New Order
/*
Sure, you can use this feature simply to extract the contents of the collection 
in the desired. But you can also combine a SELECT-FROM (TABLE) with BULK COLLECT 
to write the newly-ordered data back into the collection.
*/

DECLARE 
   l_employees   my_arrays.employees_t; 
   l_employees2   my_arrays.employees_t; 
BEGIN 
   DBMS_OUTPUT.PUT_LINE ('Sort by Last Name'); 
 
   /* Fill the collection from the table to  
      get things started. */ 
 
   SELECT * 
     BULK COLLECT INTO l_employees 
     FROM employees; 
 
   /* Re-order the contents of the collection  
      using SQL */ 
 
   SELECT * 
     BULK COLLECT INTO l_employees2 
     FROM TABLE (l_employees) 
    ORDER BY last_name; 
 
   /* Iterate through collection by index value 
      to verify new order. */ 
 
   FOR indx IN 1 .. l_employees2.COUNT 
   LOOP 
      DBMS_OUTPUT.put_line (l_employees2(indx).last_name); 
   END LOOP; 
END;
/

