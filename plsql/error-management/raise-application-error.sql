/*
If you execute a SELECT-INTO that does not identify any rows, the PL/SQL runtime 
engine raises: ORA-01403 and the error message (retrieved via SQLERRM or 
DBMS_UTILITY.FORMAT_ERROR_STACK) is simply "No data found".

That may be exactly what you want your users to see. But there is a very good chance 
you'd like to offer something more informative, such as "An employee with that ID is not in the system."

In this case, you can use RAISE_APPLICATION_ERROR.
*/

CREATE OR REPLACE PACKAGE employees_mgr AUTHID DEFINER
IS
   FUNCTION onerow (employee_id_in IN hr.employees.employee_id%TYPE)
      RETURN hr.employees%ROWTYPE
      RESULT_CACHE;
END;
/

-- Trap NO_DATA_FOUND, Change Message
-- In this function, I trap the NO_DATA_FOUND exception, raised by the SELECT-INTO, 
-- and then I convert this "generic" error into something specific for my users.

CREATE OR REPLACE PACKAGE BODY employees_mgr 
IS 
   FUNCTION onerow (employee_id_in IN hr.employees.employee_id%TYPE) 
      RETURN hr.employees%ROWTYPE 
      RESULT_CACHE 
   IS 
      l_employee hr.employees%ROWTYPE; 
   BEGIN 
      SELECT * 
        INTO l_employee 
        FROM hr.employees 
       WHERE employee_id = employee_id_in; 
 
      RETURN l_employee; 
   EXCEPTION 
      WHEN NO_DATA_FOUND 
      THEN 
         raise_application_error ( 
            -20000, 
            'An employee with ID ' || employee_id_in  || ' is not in the system.'); 
   END; 
END;
/

DECLARE
   l_employee hr.employees%ROWTYPE;
BEGIN
   l_employee := employees_mgr.onerow (-100);
END;
/

