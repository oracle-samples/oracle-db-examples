/*
This simple package uses DBMS_UTILITY.GET_CPU_TIME to calculate the elapsed time, 
down to the hundredth of a second, of code execution. Very useful for comparing 
performance of different implementations. 
*/

CREATE OR REPLACE PACKAGE tmr  
IS  
   PROCEDURE start_timer;  
  
   PROCEDURE show_elapsed_time (message_in IN VARCHAR2 := NULL);  
END;
/

CREATE OR REPLACE PACKAGE BODY tmr  
IS  
   last_timing   NUMBER;  
  
   PROCEDURE start_timer  
   IS  
   BEGIN  
      last_timing := DBMS_UTILITY.GET_CPU_TIME;  
   END;  
  
   PROCEDURE show_elapsed_time (message_in IN VARCHAR2 := NULL)  
   IS  
   BEGIN  
      DBMS_OUTPUT.put_line (  
            CASE  
               WHEN message_in IS NULL THEN 'Completed in:'  
               ELSE '"' || message_in || '" completed in: '  
            END  
         || TO_CHAR (ROUND ((DBMS_UTILITY.GET_CPU_TIME - last_timing) / 100, 2)) 
         || ' seconds');  
  
      /* Reset timer */  
      start_timer;  
   END;  
END;  
/

DECLARE 
   n NUMBER; 
BEGIN 
   tmr.start_timer; 
 
   FOR i IN 1 .. 50000 
   LOOP 
      SELECT 1 INTO n 
        FROM dual; 
   END LOOP; 
 
   DBMS_OUTPUT.PUT_LINE (n); 
   tmr.show_elapsed_time ('5K queries'); 
END;
/


