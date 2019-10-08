/*
UTL_CALL_STACK, introduced in Oracle Database 12c, offers fine-grained access to 
the execution call stack, error stack, and backtrace information. Prior to 
UTL_CALL_STACK, developers used functions in DBMS_UTILITY to obtain this infromation: 
FORMAT_CALL_STACK, FORMAT_ERROR_STACK, FORMAT_ERROR_BACKTRACE. 
The my_utl_call_stack offers functions of the same name to replace those functions.
*/

CREATE OR REPLACE PACKAGE my_utl_call_stack 
   AUTHID DEFINER 
IS 
   FUNCTION format_call_stack RETURN VARCHAR2; 
   FUNCTION format_error_stack RETURN VARCHAR2; 
   FUNCTION format_error_backtrace RETURN VARCHAR2; 
   FUNCTION backtrace_to RETURN VARCHAR2; 
END;
/

CREATE OR REPLACE PACKAGE BODY my_utl_call_stack
IS
   FUNCTION format_call_stack
      RETURN VARCHAR2
   IS
      l_return   VARCHAR2 (32767)
         :=    '----- PL/SQL Call Stack -------'
            || CHR (10)
            || 'Line     Object name'
            || CHR (10)
            || '-------- ----------------------';
   BEGIN
      /* 1 is always this function, so ignore it. */
      FOR indx IN 2 .. utl_call_stack.dynamic_depth
      LOOP
         l_return :=
               l_return
            || case when l_return is not null then CHR (10) end
            || LPAD (TO_CHAR (utl_call_stack.unit_line (indx)), 8)
            || ' '
            || utl_call_stack.owner (indx)
            || '.'
            || utl_call_stack.concatenate_subprogram (
                  utl_call_stack.subprogram (indx));
      END LOOP;

      RETURN l_return;
   END;

   FUNCTION format_error_stack
      RETURN VARCHAR2
   IS
      l_return   VARCHAR2 (32767);
   BEGIN
      FOR indx IN 1 .. utl_call_stack.error_depth
      LOOP
         l_return :=
               l_return
            || case when l_return is not null then CHR (10) end
            || 'ORA-'
            || LPAD (TO_CHAR (utl_call_stack.error_number (indx)), 5, '0')
            || ': '
            || utl_call_stack.error_msg (indx);
      END LOOP;

      RETURN l_return;
   END;

   FUNCTION format_error_backtrace
      RETURN VARCHAR2
   IS
      l_return   VARCHAR2 (32767);
   BEGIN
      FOR indx IN 1 .. utl_call_stack.backtrace_depth
      LOOP
         l_return :=
               l_return
            || case when l_return is not null then CHR (10) end
            || indx
            || ' -> '
            || utl_call_stack.backtrace_unit (indx)
            || ' - Line '
            || TO_CHAR (utl_call_stack.backtrace_line (indx));
      END LOOP;

      RETURN l_return;
   EXCEPTION
      WHEN OTHERS
      THEN
         IF SQLCODE = -64610
         THEN
            /* ORA-64610: bad depth indicator */
            RETURN l_return;
         ELSE
            RAISE;
         END IF;
   END;
   
   FUNCTION backtrace_to
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN    utl_call_stack.backtrace_unit (1)
             || ' on line '
             || utl_call_stack.backtrace_line (1);
   END;
END;
/

SET SERVEROUTPUT ON


CREATE OR REPLACE PROCEDURE p1  
IS  
   PROCEDURE nested_in_p1  
   IS  
   BEGIN  
      DBMS_OUTPUT.put_line ('Call Stack from DBMS_UTILITY');  
      DBMS_OUTPUT.put_line ('-');  
      DBMS_OUTPUT.put_line (DBMS_UTILITY.format_call_stack);  
      DBMS_OUTPUT.put_line ('-');  
      DBMS_OUTPUT.put_line ('Call Stack from UTL_CALL_STACK');  
      DBMS_OUTPUT.put_line ('-');  
      DBMS_OUTPUT.put_line (my_utl_call_stack.format_call_stack);  
      RAISE NO_DATA_FOUND;  
   END;  
BEGIN  
   nested_in_p1;  
END;
/

CREATE OR REPLACE PACKAGE pkg
   AUTHID DEFINER
IS
   PROCEDURE p;
END;
/

CREATE OR REPLACE PACKAGE BODY pkg
IS
   PROCEDURE p
   IS
   BEGIN
      p1;
   END;
END;
/

CREATE OR REPLACE PROCEDURE p2
   AUTHID DEFINER
IS
BEGIN
   pkg.p;
END;
/

CREATE OR REPLACE PROCEDURE p3  
   AUTHID DEFINER  
IS  
BEGIN  
   p2;  
EXCEPTION  
   WHEN OTHERS  
   THEN  
      DBMS_OUTPUT.put_line ('-');  
  
      DBMS_OUTPUT.put_line ('Error Stack from DBMS_UTILTY');  
      DBMS_OUTPUT.put_line ('-');  
      DBMS_OUTPUT.put_line (DBMS_UTILITY.format_error_stack);  
  
      DBMS_OUTPUT.put_line ('Error Stack from UTL_CALL_STACK');  
      DBMS_OUTPUT.put_line ('-');  
      DBMS_OUTPUT.put_line (my_utl_call_stack.format_error_stack);  
        
      DBMS_OUTPUT.put_line ('-');  
        
      DBMS_OUTPUT.put_line ('Backtrace from DBMS_UTILITY');  
      DBMS_OUTPUT.put_line ('-');  
      DBMS_OUTPUT.put_line (DBMS_UTILITY.format_error_backtrace);  
      DBMS_OUTPUT.put_line ('-');  
      DBMS_OUTPUT.put_line ('Backtrace from UTL_CALL_STACK');  
      DBMS_OUTPUT.put_line ('-');  
      DBMS_OUTPUT.put_line (my_utl_call_stack.format_error_backtrace);  
      DBMS_OUTPUT.put_line ('-');  
      DBMS_OUTPUT.put_line ('Backtrace to: ' || my_utl_call_stack.backtrace_to());  
      RAISE;  
END;
/

BEGIN  
   p3;  
  
/* Trapping the exception because if I do not, LiveSQL will not   
   show the contents of the DBMS_OUTPUT buffer.   
*/  
  
EXCEPTION WHEN OTHERS  
   THEN  
      NULL; 
END;
/

