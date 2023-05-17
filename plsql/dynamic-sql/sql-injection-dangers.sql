/*
Just when you thought your dynamic SQL was safe! This script offers a simple 
example of how dynamic SQL that contains concatenation (as opposed to binding) 
can be subverted to serve possibly malicious purposes. 
*/

CREATE OR REPLACE PACKAGE sql_injection_demo  
IS  
   TYPE name_sal_rt IS RECORD (  
      last_name   VARCHAR2(1000) 
    , salary      NUMBER 
   );  
  
   FUNCTION name_sal_for (where_in IN VARCHAR2 DEFAULT NULL)  
      RETURN sys_refcursor;  
  
   PROCEDURE show_name_sal (  
      title_in IN VARCHAR2  
    , rows_inout IN OUT sys_refcursor  
   );  
END sql_injection_demo; 
/

-- Danger! Danger! Danger!
-- Notice that concatenation of an entire WHERE clause. So flexible, so enticing....so dangerous!
CREATE OR REPLACE PACKAGE BODY sql_injection_demo  
IS  
   FUNCTION name_sal_for (where_in IN VARCHAR2 DEFAULT NULL)  
      RETURN sys_refcursor  
   IS  
      l_query   VARCHAR2 (32767)  
              := 'select last_name, salary from employees WHERE ' || where_in;  
      l_cursor        sys_refcursor;  
   BEGIN  
      OPEN l_cursor FOR l_query;  
  
      RETURN l_cursor;  
   END name_sal_for;  
  
   PROCEDURE show_name_sal (  
      title_in IN VARCHAR2  
    , rows_inout IN OUT sys_refcursor  
   )  
   IS  
      l_employee   name_sal_rt;  
   BEGIN  
      DBMS_OUTPUT.put_line (RPAD ('=', 100, '='));  
      DBMS_OUTPUT.put_line ('SQL Injection Demonstration: ' || title_in);  
  
      LOOP  
         FETCH rows_inout  
          INTO l_employee;  
         EXIT WHEN rows_inout%NOTFOUND;  
  
         DBMS_OUTPUT.put_line (l_employee.last_name || '-'  
                               || l_employee.salary  
                              );  
      END LOOP;  
  
      CLOSE rows_inout;  
   END show_name_sal;  
END sql_injection_demo; 
/

-- That's a Funny WHERE Clause!
-- Yep. I can just append a UNION to end of a "normal" WHERE clause predicate, and go crazy.
DECLARE  
   l_rows   sys_refcursor;  
BEGIN  
   l_rows := sql_injection_demo.name_sal_for ('department_id = 100');  
   sql_injection_demo.show_name_sal ('Department 100', l_rows);  
   --  
   l_rows :=  
      sql_injection_demo.name_sal_for  
                    (   'department_id = 100'  
                     || ' UNION select ''USER: '' || username, 1 from all_users'  
                    );  
   sql_injection_demo.show_name_sal ('Department 100 PLUS Users', l_rows);  
END; 
/

