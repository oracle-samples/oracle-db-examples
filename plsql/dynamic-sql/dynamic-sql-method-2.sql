/*
 Method 2 means your dynamically-constructed SQL statement in a non-query DML 
 (insert, update, delete, merge) with a fixed number of bind variables. 
 That is, at the time you are writing your code, you know how many variables 
 you must bind into placeholders.
*/

-- Copy Table from HR to Change It
CREATE TABLE employees 
AS 
   SELECT * FROM hr.employees;

-- Silly Little Helper Function
/*
This is dynamic SQL method 3, by the way: a SELECT with fixed number of bind 
variables and/or SELECT list elements (INTO clause). We take basic steps to 
guard against SQL injection with the DBMS_ASSERT package. But there is still 
a GAPING HOLE with the WHERE clause. Thus, this program should never be callable 
directly by a user, with un-checked user input. 
*/

CREATE OR REPLACE FUNCTION table_count (   
   table_name_in   IN all_tables.table_name%TYPE,  
   where_in        IN VARCHAR2 DEFAULT NULL)  
   RETURN PLS_INTEGER  
   AUTHID CURRENT_USER  
IS  
   l_table_name   all_tables.table_name%TYPE;  
   l_return       PLS_INTEGER;  
BEGIN  
   l_table_name := sys.DBMS_ASSERT.sql_object_name (table_name_in);  
   EXECUTE IMMEDIATE  
      'SELECT COUNT(*) FROM ' || table_name_in || ' WHERE ' || where_in  
      INTO l_return;  
  
   RETURN l_return;  
END;
/

-- Can't Bind Column Names
/*
First of all, remember: you can only bind variable values. You cannot bind parts 
of the SQL statement that are needed at the time the statement is parsed, such 
as the table name, column name, where clause, etc. This code will compile, but fail to run.
*/

CREATE OR REPLACE PROCEDURE set_to_10000 (col_in             IN VARCHAR2, 
                                          department_id_in   IN PLS_INTEGER) 
IS 
   l_update CONSTANT VARCHAR2 (1000) :=  
      'UPDATE employees SET :colname = 10000  
        WHERE department_id = :dept'; 
BEGIN 
   EXECUTE IMMEDIATE l_update USING col_in, department_id_in; 
 
   DBMS_OUTPUT.put_line ('Rows updated: ' || TO_CHAR (SQL%ROWCOUNT)); 
END;
/

-- Can't Bind Column Names - In Action
BEGIN 
   set_to_10000 ('salary', 50); 
/* ORA-01747: invalid user.table.column, table.column, or column specification */ 
END;
/

-- Bind Single Variable
/*
Now I concatenate in the name of the column - which introduces the possibility of 
SQL injection, so watch out! I bind the department ID. Each placeholder - in the
form :name, where name could also be an integer value - must have a corresponding 
value in the USING clause.
*/

CREATE OR REPLACE PROCEDURE set_to_10000 (col_in             IN VARCHAR2, 
                                          department_id_in   IN PLS_INTEGER) 
IS 
   l_update   VARCHAR2 (1000) 
      :=    'UPDATE employees SET ' 
         || col_in 
         || ' = 10000  
        WHERE department_id = :dept'; 
BEGIN 
   EXECUTE IMMEDIATE l_update USING department_id_in; 
 
   DBMS_OUTPUT.put_line ('Rows updated: ' || TO_CHAR (SQL%ROWCOUNT)); 
END;
/

BEGIN 
   DBMS_OUTPUT.put_line ( 
         'Before ' 
      || table_count ('employees', 
                      'department_id = 50 AND salary = 10000')); 
 
   set_to_10000 ('salary', 50); 
 
   DBMS_OUTPUT.put_line ( 
         'After ' 
      || table_count ('employees', 
                      'department_id = 50 AND salary = 10000')); 
   ROLLBACK; 
END;
/

-- Multiple Placeholders, Different Names
-- I have two placeholders with different names. I therefore have two expressions in the USING clause.
CREATE OR REPLACE PROCEDURE updnumval (col_in             IN VARCHAR2, 
                                       department_id_in   IN PLS_INTEGER, 
                                       val_in             IN NUMBER) 
IS 
   l_update   VARCHAR2 (1000) 
      :=    'UPDATE employees SET ' 
         || col_in 
         || ' = :val  
        WHERE department_id = :dept'; 
BEGIN 
   EXECUTE IMMEDIATE l_update USING val_in, department_id_in; 
 
   DBMS_OUTPUT.put_line ('Rows updated: ' || TO_CHAR (SQL%ROWCOUNT)); 
END;
/

BEGIN 
   DBMS_OUTPUT.put_line ( 
         'Before ' 
      || table_count ('employees', 
                      'department_id = 50 AND salary = 10000')); 
 
   updnumval ('salary', 50, 10000); 
 
   DBMS_OUTPUT.put_line ( 
         'After ' 
      || table_count ('employees', 
                      'department_id = 50 AND salary = 10000')); 
   ROLLBACK; 
END;
/

-- Three Placeholders, Repeating Names
-- Now I have three placeholders and the name "val" is used twice. When I execute a dynamic SQL statement, I must have an expression in the USING clause for each placeholder - by position, not name. So you see three variables, including val_in twice. Of course, I could use a different expression for the second "val" placeholder. They are NOT connected by name.
CREATE OR REPLACE PROCEDURE updnumval (col_in             IN VARCHAR2, 
                                       department_id_in   IN PLS_INTEGER, 
                                       val_in             IN NUMBER) 
IS 
   l_update   VARCHAR2 (1000) 
      :=    'UPDATE employees SET ' 
         || col_in 
         || ' = :val  
        WHERE department_id = :dept and :val IS NOT NULL'; 
BEGIN 
   EXECUTE IMMEDIATE l_update USING val_in, department_id_in, val_in; 
 
   DBMS_OUTPUT.put_line ('Rows updated: ' || TO_CHAR (SQL%ROWCOUNT)); 
END;
/

BEGIN 
   DBMS_OUTPUT.put_line ( 
         'Before ' 
      || table_count ('employees', 
                      'department_id = 50 AND salary = 10000')); 
 
   updnumval ('salary', 50, 10000); 
 
   DBMS_OUTPUT.put_line ( 
         'After ' 
      || table_count ('employees', 
                      'department_id = 50 AND salary = 10000')); 
   ROLLBACK; 
END;
/

