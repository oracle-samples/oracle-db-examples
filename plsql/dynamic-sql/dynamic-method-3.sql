/*
Method 3 Dynamic SQL: a SELECT statement whose select list (number of elements 
returned by the query) and bind variables are fixed at compile-time. For more 
information on dynamic SQL in PL/SQL: 

https://stevenfeuersteinonplsql.blogspot.com/2016/07/a-quick-guide-to-writing-dynamic-sql-in.html
*/

CREATE TABLE employees 
AS 
   SELECT * FROM hr.employees ;

-- Concatenate Table Name, Bind One Variable, Return Two Values
-- Yes, all of that! Notice that I don't trust the table name provided. 
-- I use DBMS_ASSERT to make sure it's a valid table name. 
DECLARE  
   l_last_name   employees.last_name%TYPE;  
   l_salary      employees.salary%TYPE;  
  
   PROCEDURE show_value (table_in IN VARCHAR2, id_in IN INTEGER)  
   IS  
   BEGIN  
      EXECUTE IMMEDIATE  
            'SELECT last_name, salary FROM '  
         || sys.DBMS_ASSERT.sql_object_name (table_in)  
         || ' WHERE employee_id = :id_value'  
         INTO l_last_name, l_salary  
         USING id_in;  
  
      DBMS_OUTPUT.put_line (l_last_name || ' Earning ' || l_salary);  
   END;  
BEGIN  
   show_value ('EMPLOYEES', 138);  
END; 
/

DECLARE 
   l_employee   employees%ROWTYPE; 
BEGIN 
   EXECUTE IMMEDIATE 'SELECT * FROM EMPLOYEES WHERE EMPLOYEE_ID = :empid' 
      INTO l_employee 
      USING 138; 
 
   DBMS_OUTPUT.put_line (l_employee.last_name); 
END allrows_by; 
/

-- Use BULK COLLECT with EXECUTE IMMEDIATE
-- Sure, why not? Get all or specified set of rows and load a collection!
DECLARE  
   TYPE employee_ntt IS TABLE OF employees%ROWTYPE;  
  
   l_employees   employee_ntt;  
BEGIN  
   EXECUTE IMMEDIATE 'SELECT * FROM employees' BULK COLLECT INTO l_employees;  
  
   DBMS_OUTPUT.put_line (l_employees.COUNT);  
END allrows_by; 
/

-- Use OPEN FOR to Fetch From Dynamic SELECT
-- In Oracle8, when native dynamic SQL was first introduced, you could not 
-- use BULK COLLECT with EXECUTE IMMEDIATE. So, instead, you could use OPEN 
-- FOR to assign a cursor variable to the dynamic SELECT, and then FETCH BULK COLLECT.

DECLARE  
   l_cursor      SYS_REFCURSOR;  
  
   TYPE employee_ntt IS TABLE OF employees%ROWTYPE;  
  
   l_employees   employee_ntt;  
BEGIN  
   OPEN l_cursor FOR 'SELECT * FROM employees';  
  
   FETCH l_cursor BULK COLLECT INTO l_employees;  
  
   DBMS_OUTPUT.put_line (l_employees.COUNT);  
  
   CLOSE l_cursor;  
END allrows_by; 
/

-- And With a LIMIT Clause
DECLARE  
   l_cursor      SYS_REFCURSOR;  
  
   TYPE employee_ntt IS TABLE OF employees%ROWTYPE;  
  
   l_employees   employee_ntt;  
BEGIN  
   OPEN l_cursor FOR 'SELECT * FROM employees';  
  
   LOOP  
      FETCH l_cursor BULK COLLECT INTO l_employees LIMIT 100;  
  
      EXIT WHEN l_employees.COUNT = 0;  
  
      DBMS_OUTPUT.put_line (l_employees.COUNT);  
   END LOOP;  
  
   CLOSE l_cursor;  
END allrows_by; 
/

