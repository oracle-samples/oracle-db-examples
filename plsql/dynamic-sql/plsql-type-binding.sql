/*
In 12.1, Oracle Database extended its support for PL/SQL-specific datatypes in SQL statements. 
Before Oracle Database 12c, values with PL/SQL-only data types (for example, BOOLEAN, 
associative array, and record) could not be bound from client programs (OCI or JDBC) 
or from static and native dynamic SQL issued from PL/SQL in the server. As of Oracle 
Database 12c, it is possible to bind values with PL/SQL-only data types to anonymous 
blocks (which are SQL statements), PL/SQL function calls in SQL queries and CALL statements, 
and the TABLE operator in SQL queries. 

http://docs.oracle.com/database/121/LNPLS/release_changes.htm#LNPLS111
*/

-- Function with Boolean Parameter
-- Prior to 12.1, you could not execute this function inside a SQL statement.
CREATE OR REPLACE FUNCTION uc_last_name (  
   employee_id_in   IN employees.employee_id%TYPE,  
   upper_in         IN BOOLEAN)  
   RETURN employees.last_name%TYPE  
IS  
   l_return   employees.last_name%TYPE;  
BEGIN  
   SELECT last_name  
     INTO l_return  
     FROM employees  
    WHERE employee_id = employee_id_in;  
  
   RETURN CASE WHEN upper_in THEN UPPER (l_return) ELSE l_return END;  
END; 
/

-- Reference a Boolean Inside SQL!
-- Hurray! Note, however, that a direct reference to a Boolean literal will NOT work, as in uc_last_name (employee_id, TRUE)
DECLARE 
   b BOOLEAN := TRUE; 
BEGIN  
   FOR rec IN (SELECT uc_last_name (employee_id, b) lname  
                 FROM employees  
                WHERE department_id = 10)  
   LOOP  
      DBMS_OUTPUT.put_line (rec.lname);  
   END LOOP;  
END; 
/

-- Bind Boolean in Dynamic SQL
DECLARE  
   l_uc   BOOLEAN := TRUE;  
BEGIN  
   EXECUTE IMMEDIATE  
      'BEGIN DBMS_OUTPUT.PUT_LINE (uc_last_name (138, :b)); END;'  
      USING l_uc;  
END; 
/

CREATE OR REPLACE FUNCTION is_it_null (value_in IN VARCHAR2) 
   RETURN BOOLEAN 
IS 
BEGIN 
   RETURN value_in IS NULL; 
END; 
/

-- Bind Variable to Boolean Returned by Function
-- Yep, that works, too - so long as you remember to add the OUT clause to USING! (My first attempts failed due to this).
DECLARE  
   l_uc   BOOLEAN := TRUE;  
BEGIN  
   EXECUTE IMMEDIATE 'BEGIN :is_it_null := is_it_null (''abc''); END;'  
      USING OUT l_uc;  
END; 
/

CREATE OR REPLACE FUNCTION f (x BOOLEAN, y PLS_INTEGER) 
   RETURN employees.employee_id%TYPE 
   AUTHID CURRENT_USER 
AS 
BEGIN 
   IF x 
   THEN 
      RETURN y; 
   ELSE 
      RETURN 2 * y; 
   END IF; 
END; 
/

-- More Fun with Booleans in SELECTs
-- I can't stop! It's too much fun!
DECLARE  
   name   employees.last_name%TYPE;  
   b      BOOLEAN := TRUE;  
BEGIN  
   SELECT last_name  
     INTO name  
     FROM employees  
    WHERE employee_id = f (b, 100);  
  
   DBMS_OUTPUT.put_line (name);  
 
   b := FALSE;  
  
   SELECT last_name  
     INTO name  
     FROM employees  
    WHERE employee_id = f (b, 100);  
  
   DBMS_OUTPUT.put_line (name);  
END; 
/

-- Package with Collection of Records (Type)
-- Can we use this associative array type inside SQL with TABLE operator?
CREATE OR REPLACE PACKAGE pkg  
   AUTHID DEFINER  
AS  
   TYPE rec IS RECORD  
   (  
      f1   NUMBER,  
      f2   VARCHAR2 (30)  
   );  
  
   TYPE mytab IS TABLE OF rec  
      INDEX BY PLS_INTEGER;  
END; 
/

-- Yes We Can! (in 12.1)
-- Use of TABLE is no longer restricted to nested tables and varrays.
DECLARE  
   v1   pkg.mytab;    
   v2   pkg.rec;  
   c1   SYS_REFCURSOR;  
BEGIN  
   OPEN c1 FOR SELECT * FROM TABLE (v1);  
  
   FETCH c1 INTO v2;  
  
   CLOSE c1;  
END; 
/

-- First, TABLE Operator with Nested Table
-- This has been possible for several versions of Oracle before 12.1.
CREATE OR REPLACE TYPE list_of_names_t IS TABLE OF VARCHAR2 (100); 
/

DECLARE 
   happyfamily   list_of_names_t 
                    := list_of_names_t ('Sally', 'Sam', 'Agatha'); 
BEGIN 
   FOR rec IN (  SELECT COLUMN_VALUE family_name 
                   FROM TABLE (happyfamily) 
               ORDER BY family_name) 
   LOOP 
      DBMS_OUTPUT.put_line (rec.family_name); 
   END LOOP; 
END; 
/

-- Now TABLE with Package-based Associative Array Type
CREATE OR REPLACE PACKAGE names_pkg  
IS  
   TYPE list_of_names_t IS TABLE OF VARCHAR2 (100)  
      INDEX BY PLS_INTEGER;  
END; 
/

-- Read-Consistency with TABLE (Array)
-- Just like with selecting from a relational table, even when I delete elements 
-- from the collection referenced in TABLE(), those changes are not reflected in the dataset returned by the query!
DECLARE  
   happyfamily   names_pkg.list_of_names_t;  
BEGIN  
   happyfamily (1) := 'Sally';  
   happyfamily (2) := 'Sam';  
   happyfamily (3) := 'Agatha';  
  
   FOR rec IN (  SELECT COLUMN_VALUE family_name  
                   FROM TABLE (happyfamily)  
               ORDER BY family_name)  
   LOOP  
      happyfamily.delete;  
      DBMS_OUTPUT.put_line (rec.family_name);  
      DBMS_OUTPUT.put_line (happyfamily.COUNT);  
   END LOOP;  
  
   DBMS_OUTPUT.put_line (happyfamily.COUNT);  
END; 
/

-- Bind a User-Defined Record Type
-- Again, not possible before 12.1!
CREATE OR REPLACE PACKAGE rec_pkg  
AS 
   TYPE rec_t IS RECORD ( 
      number1   NUMBER, 
      number2   NUMBER 
   ); 
 
   PROCEDURE set_rec (n1_in IN NUMBER, n2_in IN NUMBER,  
      rec_out OUT rec_t); 
END rec_pkg; 
/

-- Bind a User-Defined Record Type
-- Again, not possible before 12.1!
CREATE OR REPLACE PACKAGE BODY rec_pkg 
AS 
   PROCEDURE set_rec (n1_in IN NUMBER, n2_in IN NUMBER,  
      rec_out OUT rec_t) 
   AS 
   BEGIN 
      rec_out.number1 := n1_in; 
      rec_out.number2 := n2_in; 
   END set_rec; 
END rec_pkg; 
/

-- Bind a User-Defined Record Type
-- Again, not possible before 12.1!
DECLARE 
   l_record  rec_pkg.rec_t; 
BEGIN 
   EXECUTE IMMEDIATE 'BEGIN rec_pkg.set_rec (10, 20, :rec); END;'  
      USING OUT l_record; 
 
   DBMS_OUTPUT.put_line ('number1 = ' || l_record.number1); 
   DBMS_OUTPUT.put_line ('number2 = ' || l_record.number2); 
END; 
/

