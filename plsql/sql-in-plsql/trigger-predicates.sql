REM   Script: DML Trigger Conditional Predicates: INSERTING, UPDATING, DELETING
REM   The triggering event of a DML trigger can be composed of multiple triggering statements. When one of them fires the trigger, the trigger can determine which one by using these conditional predicates: INSERTING, UPDATING, UPDATING ('column_name'), DELETING. Very useful when you need to run similar (but not same) logic for different events. Put it all in one trigger with branching logic.

Link to doc: http://docs.oracle.com/database/121/LNPLS/triggers.htm#LNPLS750

-- Silly Little Employees Table
CREATE TABLE employees ( 
   last_name VARCHAR2(100), 
   salary NUMBER, 
   department_id INTEGER) ;

BEGIN 
   INSERT INTO employees VALUES ('Polly', 1000, 10); 
   INSERT INTO employees VALUES ('Molly', 5673, 60); 
   INSERT INTO employees VALUES ('Golly', 23409, 60); 
   COMMIT; 
END; 
/

-- Utility Procedure to Display Values
-- Note that I can compile code with the conditional predicates (I generally just call them event functions, that seems clearer) outside of a DML trigger. Note also that you can pass a column name to UPDATING to determine if that particular column is being changed.
CREATE OR REPLACE PROCEDURE show_trigger_event  
IS  
BEGIN  
   DBMS_OUTPUT.put_line (CASE  
                            WHEN UPDATING ('last_name') THEN 'UPDATE last_name'  
                            WHEN UPDATING THEN 'UPDATE'  
                            WHEN INSERTING THEN 'INSERT'  
                            WHEN DELETING THEN 'DELETE'  
                            ELSE 'Procedure not executed from DML trigger!'  
                         END);  
END; 
/

-- AFTER UPDATE OR INSERT Trigger
-- I call the procedure from within. 
CREATE OR REPLACE TRIGGER employee_changes_after 
   AFTER UPDATE OR INSERT  
   ON employees  
BEGIN  
   show_trigger_event;  
END; 
/

-- A BEFORE DELETE Trigger
-- Calling the same procedure.
CREATE OR REPLACE TRIGGER employee_changes_before  
   BEFORE DELETE 
   ON employees  
BEGIN  
   show_trigger_event;  
END; 
/

-- Test It Out
BEGIN  
   show_trigger_event;  
  
   UPDATE employees  
      SET last_name = UPPER (last_name);  
  
   UPDATE employees  
      SET salary = salary * 10 
    WHERE department_id = 10;  
 
   DELETE FROM employees WHERE department_id = 60; 
 
   INSERT INTO employees (last_name, salary, department_id) 
      VALUES ('Feuerstein', 1000000, 10); 
END; 
/

