/*
When contemplating a change to a subprogram, impact analysis is critical. 
And the first thing you need to know is: where is the subprogram called? 
With PL/Scope (11.1), you can now get the definitive answer to that question, 
regardless of possible re-uses of the same name in different program units, 
by utilizing the unique signature values stored in ALL/USER_IDENTIFIERS.
*/

-- Turn on PL/Scope
ALTER SESSION SET plscope_settings='identifiers:all' ;

-- Who Calls Me? Answered by PL/Scope
-- I look up the declaration of that subprogram in the package, then search 
-- for its signature across all other program units compiled with PL/Scope enabled.
CREATE OR REPLACE PROCEDURE who_calls_me (pkg_in    IN VARCHAR2, 
                                          prog_in   IN VARCHAR2) 
IS 
BEGIN 
   FOR rec 
      IN (SELECT srch.object_name, srch.name 
            FROM user_identifiers srch, user_identifiers src 
           WHERE     src.object_name = pkg_in 
                 AND src.object_type = 'PACKAGE' 
                 AND src.usage = 'DECLARATION' 
                 AND src.name = prog_in 
                 AND src.signature = srch.signature 
                 AND srch.usage = 'CALL') 
   LOOP 
      DBMS_OUTPUT.put_line ( 
         rec.object_name || ' calls ' || pkg_in || '.' || prog_in); 
   END LOOP; 
END;
/

-- Create Some Program Units
CREATE OR REPLACE PACKAGE my_pkg1 
IS 
   PROCEDURE my_proc; 
END;
/

CREATE OR REPLACE PACKAGE BODY my_pkg1
IS
   PROCEDURE my_proc
   IS
   BEGIN
      NULL;
   END;
END;
/

CREATE OR REPLACE PACKAGE my_pkg2
IS
   PROCEDURE my_proc;
END;
/

CREATE OR REPLACE PACKAGE BODY my_pkg2
IS
   PROCEDURE my_proc
   IS
   BEGIN
      NULL;
   END;
END;
/

CREATE OR REPLACE PROCEDURE my_proc1
IS
BEGIN
   my_pkg1.my_proc;
END;
/

CREATE OR REPLACE PROCEDURE my_proc2
IS
BEGIN
   my_pkg2.my_proc;
END;
/

-- Check for Usages
BEGIN 
   who_calls_me ('MY_PKG1', 'MY_PROC'); 
END;
/

