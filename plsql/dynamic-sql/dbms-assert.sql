/*
Use DBMS_ASSERT to help guard against SQL injection.

The DBMS_ASSERT package was introduced in Oracle 10g Release 2. It contains functions 
that help developers sanitize user input and reduce the likelihood of SQL injection 
in applications that concatenate text (they do NOT use bind variables).
*/

BEGIN 
   sys.DBMS_OUTPUT.put_line (DBMS_ASSERT.schema_name ('HR')); 
END; 
/

BEGIN 
   sys.DBMS_OUTPUT.put_line (DBMS_ASSERT.sql_object_name ('EMPLOYEES')); 
END; 
/

BEGIN 
   sys.DBMS_OUTPUT.put_line (DBMS_ASSERT.qualified_sql_name  ('HR.EMPLOYEES')); 
END; 
/

BEGIN 
   sys.DBMS_OUTPUT.put_line (DBMS_ASSERT.schema_name ('HR')); 
END; 
/

BEGIN 
   sys.DBMS_OUTPUT.put_line (DBMS_ASSERT.schema_name ('WHO_ME')); 
END; 
/

BEGIN 
   DBMS_OUTPUT.put_line ( 
      DBMS_ASSERT.sql_object_name ( 
         'EMPLOYEES, (SELECT * FROM ALL_USERS) u')); 
END; 
/

