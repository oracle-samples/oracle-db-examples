-- THIS TABLE IS CREATED FROM JAVA CODE -> SQLStatementWithAsynchronousJDBC.java -> createTable() method
-- CREATE TABLE employee_names (id NUMBER PRIMARY KEY, first_name VARCHAR2(50), last_name VARCHAR2(50))

--IF YOU WANT TO CONFIRM YOU HAVE A TABLE WHILE ON DEBUGBING MODE
DESCRIBE employee_names;

--IF YOU WANT TO CHECK THE TABLE RECORDS WHILE ON DEBUGGING MODE
SELECT * FROM employee_names;

/*

INSERT INTO employee_names (id, first_name, last_name) VALUES (1, 'John', 'Doe');

INSERT INTO employee_names (id, first_name, last_name)
VALUES (2, 'Jane', 'Smith');

INSERT INTO employee_names (id, first_name, last_name)
VALUES (3, 'David', 'Lee');

INSERT INTO employee_names (id, first_name, last_name)
VALUES (4, 'Emily', 'Jones');

INSERT INTO employee_names (id, first_name, last_name)
VALUES (5, 'Michael', 'Brown');
COMMIT;

*/

/*
-- TABLE IS DROPPED FROM JAVA CODE -> SQLStatementWithAsynchronousJDBC.java -> dropTable() method
DROP TABLE employee_names;
COMMIT;
*/
