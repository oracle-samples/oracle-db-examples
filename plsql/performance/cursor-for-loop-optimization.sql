/*
This script demonstrates that when you have the PL/SQL optimization 
level set to at least 2, the PL/SQL compiler will optimize cursor FOR 
loops to perform comparably to using BULK COLLECT. It's a very nice, 
specialized optimization for a database programming language and reinforces 
an important rule: always use the highest level declarative statement 
possible in PL/SQL (and any other language). That way, you give the 
compiler maximum freedom to optimization.
*/

-- Create Driver for Test
/*
I generate 100,000 rows for my cursor using by CONNECT BY LEVEL (thanks, Tom Kyte!). 
Then I iterate through the rows of that cursor in 1 of 3 ways: with a cursor FOR 
loop, with an explicit open-fetch-close loop, and using BULK COLLECT. Within each 
loop, I do just enough to avoid having the super-smart optimizer negate the whole 
thing. 
*/

CREATE OR REPLACE PROCEDURE test_cursor_performance (approach IN VARCHAR2) 
IS 
   CURSOR cur 
   IS 
      SELECT * 
        FROM dual 
       CONNECT BY LEVEL < 100001; 
 
   one_row     cur%ROWTYPE; 
 
   TYPE t IS TABLE OF cur%ROWTYPE 
                INDEX BY PLS_INTEGER; 
 
   many_rows   t; 
    
   last_timing   TIMESTAMP; 
 
   cntr number := 0; 
 
   PROCEDURE start_timer 
   IS 
   BEGIN 
      last_timing := SYSTIMESTAMP; 
   END; 
 
   PROCEDURE show_elapsed_time (message_in IN VARCHAR2 := NULL) 
   IS 
   BEGIN 
      DBMS_OUTPUT.put_line ( 
            CASE 
               WHEN message_in IS NULL THEN 'Completed in:' 
               ELSE '"' || message_in || '" completed in: ' 
            END 
         || REGEXP_SUBSTR (SYSTIMESTAMP - last_timing,  
               '([1-9][0-9:]*|0)\.\d{3}') 
         || ' seconds'); 
   END; 
BEGIN 
   start_timer; 
 
   CASE approach 
      WHEN 'implicit cursor for loop' 
      THEN 
         FOR j IN cur 
         LOOP 
            cntr := cntr + 1; 
         END LOOP; 
 
         DBMS_OUTPUT.put_line (cntr); 
 
      WHEN 'explicit open, fetch, close' 
      THEN 
         OPEN cur; 
 
         LOOP 
            FETCH cur INTO one_row; 
 
            EXIT WHEN cur%NOTFOUND; 
 
            cntr := cntr + 1; 
         END LOOP; 
 
         DBMS_OUTPUT.put_line (cntr); 
 
         CLOSE cur; 
      WHEN 'bulk fetch' 
      THEN 
         OPEN cur; 
 
         LOOP 
            FETCH cur BULK COLLECT INTO many_rows LIMIT 100; 
 
            EXIT WHEN many_rows.COUNT () = 0; 
 
            FOR indx IN 1 .. many_rows.COUNT 
            loop 
               cntr := cntr + 1; 
            end loop; 
         END LOOP; 
 
         DBMS_OUTPUT.put_line (cntr); 
 
         CLOSE cur; 
   END CASE; 
 
   show_elapsed_time (approach); 
END test_cursor_performance;
/

-- Turn off Optimization of PL/SQL Code
-- Level = 0 is the same as no optimization.
ALTER PROCEDURE test_cursor_performance COMPILE plsql_optimize_level=0;

-- Without Optimization
/*
The implicit cursor FOR loop and explicit processing are similar in performance. 
Bulk fetch is a fraction of the time.
*/
BEGIN 
   DBMS_OUTPUT.put_line ('No optimization...'); 
 
   test_cursor_performance ('implicit cursor for loop'); 
 
   test_cursor_performance ('explicit open, fetch, close'); 
 
   test_cursor_performance ('bulk fetch'); 
END;
/

-- Set Optimization to Default Level
/*
By default, your code is optimized at level 2, which offers a full load of 
code transformations to achieve better performance. Want more information? 
Check out http://www.oracle.com/technetwork/database/features/plsql/codeorder-133512.zip 
for more details on how the optimizer works.
*/

ALTER PROCEDURE test_cursor_performance COMPILE plsql_optimize_level=2;

-- Now with Optimization
/*
Note that the implicit cursor FOR loop and the bulk fetch run in similar times now. 
Very cool optimization! And the reason the PL/SQL compiler can do this is that when 
you write a cursor FOR loop, you are DESCRIBING (a la SQL) what you want to do, 
not telling the PL/SQL compiler how to do it.
*/

BEGIN 
   DBMS_OUTPUT.put_line ('Default optimization...'); 
 
   test_cursor_performance ('implicit cursor for loop'); 
 
   test_cursor_performance ('explicit open, fetch, close'); 
 
   test_cursor_performance ('bulk fetch'); 
END;
/

-- Now with Debug (Reduced Optimization)
-- COMPILE DEBUG is now deprecated, but it is the same as setting the optimization 
-- level to 1. You will then see that the optimization that improves performance of cursor FOR loops is disabled.
ALTER PROCEDURE test_cursor_performance COMPILE DEBUG;

BEGIN
   DBMS_OUTPUT.put_line ('DEBUG enabled...');

   test_cursor_performance ('implicit cursor for loop');

   test_cursor_performance ('explicit open, fetch, close');

   test_cursor_performance ('bulk fetch');
END;
/

