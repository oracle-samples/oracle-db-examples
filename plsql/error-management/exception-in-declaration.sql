/*
This sometimes surprises a developer new to PL/SQL. The exception section of a 
PL/SQL block can only possibly handle an exception raised in the executable section. 
An exception raised in the declaration section (in an attempt to assign a default 
value to a variable or constant) always propagates out unhandled to the enclosing block.
*/

-- Error Raised in Declaration Section - Not Handled
DECLARE  
   aname VARCHAR2 (5) := 'Big String';   
BEGIN  
   DBMS_OUTPUT.put_line (aname);  
EXCEPTION  
   WHEN VALUE_ERROR  
   THEN  
      DBMS_OUTPUT.put_line ('Handled!');  
END;
/

-- Trapped in Outer Block
-- Can't trap the exception in the same block (when raised in the declaration section), 
-- but certainly it is trappable in an outer block.
BEGIN 
   DECLARE  
      aname VARCHAR2 (5) := 'Big String';   
   BEGIN  
      DBMS_OUTPUT.put_line (aname);  
   EXCEPTION  
      WHEN VALUE_ERROR  
      THEN  
         DBMS_OUTPUT.put_line ('Handled!');  
   END; 
EXCEPTION 
   WHEN VALUE_ERROR 
   THEN 
      DBMS_OUTPUT.put_line ('Handled in outer block!');  
END;
/

-- What's a Developer to Do? Initialize Later!
/*
Generally, I recommend that you created a nested subprogram called 
"initialize" and move all of your initialization into that procedure. 
Then call it as the first line in your "main" subprogram. That way, 
an exception raised when assigning a value can be trapped in that 
subprogram's exception section.
*/

BEGIN 
   DECLARE  
      aname VARCHAR2 (5);  
 
      PROCEDURE initialize  
      IS 
      BEGIN 
         aname := 'Big String'; -- pkg.func (); 
      END; 
   BEGIN  
      initialize; 
 
      DBMS_OUTPUT.put_line (aname);  
   EXCEPTION  
      WHEN VALUE_ERROR  
      THEN  
         DBMS_OUTPUT.put_line ('Handled!');  
   END; 
EXCEPTION 
   WHEN VALUE_ERROR 
   THEN 
      DBMS_OUTPUT.put_line ('Handled in outer block!');  
END;
/

