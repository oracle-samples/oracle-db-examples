/*

An exploration into RAISE and RAISE_APPLICATION_ERROR, as a complement to 
Steven Feuerstein's blog post: http://stevenfeuersteinonplsql.blogspot.com/2016/09/plsql-101-raising-exceptions-in-plsql.html

LiveSQL link: https://livesql.oracle.com/apex/livesql/file/content_DT5NWAKAHQWDKMSBPS2BIODYE.html

*/

/* Explicit Raise of Pre-defined Exception */

CREATE OR REPLACE PROCEDURE use_salary (salary_in IN NUMBER) 
IS 
BEGIN 
   IF salary_in < 0  
   THEN 
      RAISE VALUE_ERROR; 
   END IF; 
END;
/

BEGIN
   use_salary (salary_in => -1);
END;
/

/* Raise a User-Defined Exception 

Which in this case simply "mimics" the pre-defined VALUE_ERROR exception and doesn't really add value.

*/

CREATE OR REPLACE PROCEDURE use_salary (salary_in IN NUMBER) 
IS 
   negative_salary EXCEPTION; 
   PRAGMA EXCEPTION_INIT (negative_salary, -6502); 
BEGIN 
   IF salary_in < 0  
   THEN 
      RAISE negative_salary; 
   END IF; 
END;
/

BEGIN 
   use_salary (salary_in => -1); 
END;
/

/* Different Code for Different Error Conditions

All the exception handling logic "front loaded" into the executable section, making it harder 
to focus on the "positive" side of things: when nothing went wrong. Not a great way to write maintainable code.

*/

CREATE OR REPLACE PROCEDURE use_salary (salary_in IN NUMBER) 
IS 
   PROCEDURE notify_support (string_in IN VARCHAR2) 
   IS 
   BEGIN 
       -- Just a placeholder to make a point! 
       DBMS_OUTPUT.PUT_LINE ('Hey support, deal with THIS: ' || string_in); 
   END; 
 
   PROCEDURE notify_hr (string_in IN VARCHAR2) 
   IS 
   BEGIN 
       -- Just a placeholder to make a point! 
       DBMS_OUTPUT.PUT_LINE ('Hey HR, deal with THIS: ' || string_in); 
   END; 
BEGIN 
   CASE 
      WHEN salary_in < 0  
      THEN  
         notify_support ( 
            'Negative salary submitted ' || salary_in);  
         RAISE VALUE_ERROR; 
      WHEN salary_in > 10000  
      THEN  
         notify_support ( 
            'Too large salary submitted ' || salary_in);  
         RAISE VALUE_ERROR; 
      WHEN salary_in < 100  
      THEN  
         notify_hr ( 
            'No one should be treated so shabbily! ' || salary_in);  
         RAISE VALUE_ERROR; 
      ELSE 
         /* No problems, proceed with normal execution*/ 
         NULL; 
   END CASE; 
 
   /* Rest of procedure */ 
END;
/

BEGIN 
   use_salary (salary_in => -1); 
END;
/

/* Move Exception Handling Logic to Exception Section

Cleaner and easier to understand, debug and maintain.

*/

CREATE OR REPLACE PROCEDURE use_salary (salary_in IN NUMBER) 
IS 
   negative_salary EXCEPTION; 
   too_large_salary EXCEPTION; 
   too_small_salary EXCEPTION; 
 
   PROCEDURE notify_support (string_in IN VARCHAR2)  
   IS  
   BEGIN  
       -- Just a placeholder to make a point!  
       DBMS_OUTPUT.PUT_LINE ('Hey support, deal with THIS: ' || string_in);  
   END;  
  
   PROCEDURE notify_hr (string_in IN VARCHAR2)  
   IS  
   BEGIN  
       -- Just a placeholder to make a point!  
       DBMS_OUTPUT.PUT_LINE ('Hey HR, deal with THIS: ' || string_in);  
   END;  
BEGIN 
   CASE 
      WHEN salary_in < 0 THEN RAISE negative_salary; 
      WHEN salary_in > 10000 THEN RAISE too_large_salary; 
      WHEN salary_in < 100 THEN RAISE too_small_salary; 
      ELSE NULL; 
   END CASE; 
 
   /* Rest of procedure */ 
 
EXCEPTION 
   WHEN negative_salary 
   THEN 
      notify_support ( 
         'Negative salary submitted ' || salary_in);  
      RAISE VALUE_ERROR; 
 
   WHEN too_large_salary 
   THEN 
      notify_support ( 
         'Too large salary submitted ' || salary_in);  
      RAISE VALUE_ERROR; 
 
   WHEN too_small_salary 
   THEN 
      notify_hr ( 
         'No one should be treated so shabbily! ' || salary_in);   
      RAISE VALUE_ERROR; 
END;
/

BEGIN 
   use_salary (salary_in => -1); 
END;
/

/* Use RAISE_APPLICATION_ERROR for App-Specific Error Message */

BEGIN 
   RAISE_APPLICATION_ERROR (-20000, 'Say whatever you want'); 
END;
/

CREATE OR REPLACE PROCEDURE use_salary (salary_in IN NUMBER) 
IS 
   negative_salary EXCEPTION; 
   too_large_salary EXCEPTION; 
   too_small_salary EXCEPTION; 
 
   PROCEDURE notify_support (string_in IN VARCHAR2)   
   IS   
   BEGIN   
       -- Just a placeholder to make a point!   
       DBMS_OUTPUT.PUT_LINE ('Hey support, deal with THIS: ' || string_in);   
   END;   
   
   PROCEDURE notify_hr (string_in IN VARCHAR2)   
   IS   
   BEGIN   
       -- Just a placeholder to make a point!   
       DBMS_OUTPUT.PUT_LINE ('Hey HR, deal with THIS: ' || string_in);   
   END;   
BEGIN 
   CASE 
      WHEN salary_in < 0 THEN RAISE negative_salary; 
      WHEN salary_in > 10000 THEN RAISE too_large_salary; 
      WHEN salary_in < 100 THEN RAISE too_small_salary; 
      ELSE NULL; 
   END CASE; 
 
   /* Rest of procedure */ 
 
EXCEPTION 
   WHEN negative_salary 
   THEN 
      notify_support ( 
         'Negative salary submitted ' || salary_in);  
      RAISE_APPLICATION_ERROR (-20001, 
         'Negative salaries are not allowed. Please re-enter.'); 
 
   WHEN too_large_salary 
   THEN 
      notify_support ( 
         'Too large salary submitted ' || salary_in);  
      RAISE_APPLICATION_ERROR (-20001, 
         'We are not nearly that generous. Please re-enter.'); 
 
   WHEN too_small_salary 
   THEN 
      notify_hr ( 
         'No one should be treated so shabbily! ' || salary_in);   
      RAISE_APPLICATION_ERROR (-20001, 
         'C''mon, a person''s gotta eat! Please re-enter.'); 
END;
/

BEGIN 
   use_salary (salary_in => -1); 
END;
/
