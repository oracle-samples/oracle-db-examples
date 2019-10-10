/*
The VALUES OF clause, like its "sister" INDICES OF, makes it easier to use 
FORALL with bind arrays that are sparse - or with bind arrays from which you 
need to select out specific elements for binding. With VALUES OF, you specify 
a collection whose element values (not the index values) specify the index 
values in the bind arrays that will be used to generate DML statements in 
the FORALL. Sound complicated? It is, sort of. It is another level of 
"indirectness" from INDICES OF, and not as commonly used. This script should 
help drive the point home, though!
*/

-- Whose Making the Big Bucks?
SELECT employee_id
  FROM employees
 WHERE salary = 10000;

-- Using VALUES OF
/*
Notice that the three element values are -77, 13067 and 1070. These in turn 
are index values in the l_employees array. And those elements in turn have the 
values 124, 123 and 129. You should therefore see in the output of the last step 
in the script that the employees with these 3 IDs now earn a $10000 salary.
*/

DECLARE
   TYPE employee_aat IS TABLE OF employees.employee_id%TYPE
      INDEX BY PLS_INTEGER;

   l_employees         employee_aat;

   TYPE values_aat IS TABLE OF PLS_INTEGER
      INDEX BY PLS_INTEGER;

   l_employee_values   values_aat;
BEGIN
   l_employees (-77) := 134;
   l_employees (13067) := 123;
   l_employees (99999999) := 147;
   l_employees (1070) := 129;
   --
   l_employee_values (100) := -77;
   l_employee_values (200) := 13067;
   l_employee_values (300) := 1070;

   --
   FORALL l_index IN VALUES OF l_employee_values
      UPDATE employees
         SET salary = 10000
       WHERE employee_id = l_employees (l_index);

   DBMS_OUTPUT.put_line (SQL%ROWCOUNT);
END;
/

-- Whose Making the Big Bucks Now?
SELECT employee_id
  FROM employees
 WHERE salary = 10000;

