/*
This script demonstrates the use of execute immediate and open-for cursor variables
to retrieve multiple rows from a dynamically constructed query.
*/

DECLARE
   TYPE name_salary_rt IS RECORD
   (
      name     VARCHAR2 (1000),
      salary   NUMBER
   );

   TYPE name_salary_aat IS TABLE OF name_salary_rt
      INDEX BY PLS_INTEGER;

   l_employees   name_salary_aat;
BEGIN
   EXECUTE IMMEDIATE 
      q'[select first_name || ' ' || last_name, salary 
           from employees
          order by salary desc]'
      BULK COLLECT INTO l_employees;

   FOR indx IN 1 .. l_employees.COUNT
   LOOP
      DBMS_OUTPUT.put_line (l_employees (indx).name);
   END LOOP;
END;
/

CREATE OR REPLACE FUNCTION names_for (department_id_in   IN INTEGER,
                                      min_salary_in      IN NUMBER)
   RETURN SYS_REFCURSOR
IS
   l_cursor   SYS_REFCURSOR;
BEGIN
   IF department_id_in IS NOT NULL
   THEN
      OPEN l_cursor FOR
         SELECT last_name
           FROM employees
          WHERE department_id = department_id_in;
   ELSE
      OPEN l_cursor FOR
         SELECT last_name
           FROM employees
          WHERE salary >= min_salary_in;
   END IF;

   RETURN l_cursor;
END;
/

DECLARE 
   TYPE name_salary_rt IS RECORD ( 
      name     VARCHAR2 (1000), 
      salary   NUMBER 
   ); 
 
   l_record   name_salary_rt; 
 
   l_cursor   SYS_REFCURSOR; 
BEGIN 
   OPEN l_cursor FOR  
      q'[select first_name || ' ' || last_name, salary  
           from employees 
          order by salary desc]'; 
 
   LOOP 
      FETCH l_cursor INTO l_record; 
 
      EXIT WHEN l_cursor%NOTFOUND; 
 
      DBMS_OUTPUT.put_line (l_record.name); 
   END LOOP; 
 
   CLOSE l_cursor; 
END;
/

DECLARE 
   TYPE name_salary_rt IS RECORD ( 
      name     VARCHAR2 (1000), 
      salary   NUMBER 
   ); 
 
   TYPE name_salary_aat IS TABLE OF name_salary_rt 
      INDEX BY PLS_INTEGER; 
 
   l_employees   name_salary_aat; 
 
   l_cursor   SYS_REFCURSOR; 
BEGIN 
   OPEN l_cursor FOR q'[select first_name || ' ' || last_name, salary  
           from employees 
          order by salary desc]'; 
 
   FETCH l_cursor BULK COLLECT INTO l_employees; 
 
   CLOSE l_cursor; 
 
   FOR indx IN 1 .. l_employees.COUNT 
   LOOP 
      DBMS_OUTPUT.put_line (l_employees (indx).name); 
   END LOOP; 
END;
/

DECLARE 
   TYPE name_salary_rt IS RECORD ( 
      name     VARCHAR2 (1000), 
      salary   NUMBER 
   ); 
 
   l_record   name_salary_rt; 
 
   l_cursor   SYS_REFCURSOR; 
BEGIN 
   OPEN l_cursor FOR q'[select first_name || ' ' || last_name, salary  
           from employees 
          order by salary desc]'; 
 
   LOOP 
      FETCH l_cursor INTO l_record; 
 
      EXIT WHEN l_cursor%NOTFOUND; 
 
      DBMS_OUTPUT.put_line (l_record.name); 
   END LOOP; 
 
   CLOSE l_cursor; 
END;
/

DECLARE 
   l_cursor        PLS_INTEGER := DBMS_SQL.open_cursor; 
   l_names         DBMS_SQL.varchar2_table; 
   l_salaries      DBMS_SQL.number_table; 
   l_fetch_count   PLS_INTEGER; 
BEGIN 
   /* Parse the query  with a dynamic WHERE clause */ 
   DBMS_SQL.parse (l_cursor, 
      q'[select first_name || ' ' || last_name, salary   
           from employees 
          order by salary desc]', 
                   DBMS_SQL.native); 
 
   /* Define the columns in the cursor for this query */ 
   DBMS_SQL.define_array (l_cursor, 
                          1, 
                          l_names, 
                          10, 
                          1); 
   DBMS_SQL.define_array (l_cursor, 
                          2, 
                          l_salaries, 
                          10, 
                          1); 
 
   /* Execute the query and fetch the rows. */ 
   l_fetch_count := DBMS_SQL.execute (l_cursor); 
 
   LOOP 
      l_fetch_count := DBMS_SQL.fetch_rows (l_cursor); 
      DBMS_SQL.COLUMN_VALUE (l_cursor, 1, l_names); 
      DBMS_SQL.COLUMN_VALUE (l_cursor, 2, l_salaries); 
 
      EXIT WHEN l_fetch_count != 10; 
   END LOOP; 
 
   FOR indx IN 1 .. l_names.COUNT 
   LOOP 
      DBMS_OUTPUT.put_line (l_names (indx)); 
   END LOOP; 
 
   DBMS_SQL.close_cursor (l_cursor); 
END;
/

