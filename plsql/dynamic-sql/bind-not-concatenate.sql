/*
When you are writing a program with dynamic SQL in it (that is, you construct 
your statement at runtime and execute it with EXECUTE IMMEDIATE or DBMS_SQL - 
most likely and preferably the former), you should make sure to bind all variable 
values into that statement, and not concatenate.
*/

-- Update Any Column In Table - Concatenation
/*
Here's a great example of a too-generic subprogram: update any numeric 
(well, I suppose it would work for strings, too) column in the employees 
table whose hire date falls within the specified range. I use concatenation 
to put it all together. That leads to lots of typing, lots of code to look out 
and lots of single quotes. It is unlikely that a program as generic as this will ever truly be needed!
*/
CREATE OR REPLACE PROCEDURE updnumval ( 
   col_in     IN   VARCHAR2 
 , start_in   IN   DATE 
 , end_in     IN   DATE 
 , val_in     IN   NUMBER 
) 
IS 
   c_format CONSTANT VARCHAR2 ( 100 ) := 'YYYYMMDDHH24MISS'; 
BEGIN 
   EXECUTE IMMEDIATE    'UPDATE employees SET ' 
                     || col_in 
                     || ' = ' 
                     || val_in 
                     || ' WHERE hire_date BETWEEN TO_DATE (''' 
                     || TO_CHAR ( start_in, c_format ) 
                     || ''', ''' 
                     || c_format 
                     || ''') AND TO_DATE (''' 
                     || TO_CHAR ( end_in, c_format ) 
                     || ''', ''' 
                     || c_format 
                     || ''')'; 
END; 
/

BEGIN 
   updnumval ('salary', 
              DATE '2002-01-01', 
              DATE '2002-12-31', 
              20000); 
END; 
/

SELECT * 
  FROM employees 
 WHERE salary = 20000 ;

-- Well You Don't Need All Those Single Quotes
/*
A rewrite of the original, still full of concatenation, but now using the Q literal 
terminator feature to specify another character as the terminator of the literal, 
so I can avoid having code like ''','''. I'm not convinced this is all that much better - 
the benefit is more obvious when you are a large dynamic SQL statement as a single 
string - full of doubled-up quotes.
*/
CREATE OR REPLACE PROCEDURE updnumval ( 
   col_in     IN   VARCHAR2 
 , start_in   IN   DATE 
 , end_in     IN   DATE 
 , val_in     IN   NUMBER 
) 
IS 
   c_format CONSTANT VARCHAR2 ( 100 ) := 'YYYYMMDDHH24MISS'; 
BEGIN 
   EXECUTE IMMEDIATE    'UPDATE employees SET ' 
                     || col_in 
                     || ' = ' 
                     || val_in 
                     || q'[ WHERE hire_date BETWEEN TO_DATE (']' 
                     || TO_CHAR ( start_in, c_format ) 
                     || q'[', ']' 
                     || c_format 
                     || q'[') AND TO_DATE (']' 
                     || TO_CHAR ( end_in, c_format ) 
                     || q'[', ']' 
                     || c_format 
                     || q'[')]'; 
END; 
/

BEGIN 
   updnumval ('salary', 
              DATE '2002-01-01', 
              DATE '2002-12-31', 
              30000); 
END; 
/

SELECT * 
  FROM employees 
 WHERE salary = 30000 ;

-- Switch to Binding with USING Clause
/*
 Now I rewrite the procedure to bind everything I can possibly bind:
 the column value, low and high dates. My code is much simpler, easier to read, 
 and is performance-optimized (more likely to avoid unnecessary parsing). 
 Note that I cannot bind in the column NAME. That information is needed in 
 order to parse the SQL statement (which comes before binding). 
*/
CREATE OR REPLACE PROCEDURE updnumval (col_in     IN VARCHAR2, 
                                       start_in   IN DATE, 
                                       end_in     IN DATE, 
                                       val_in     IN NUMBER) 
IS 
BEGIN 
   EXECUTE IMMEDIATE 
         'UPDATE employees SET ' 
      || col_in 
      || ' = :val  
        WHERE hire_date BETWEEN :lodate AND :hidate' 
      USING val_in, start_in, end_in; 
END; 
/

BEGIN 
   updnumval ('salary', 
              DATE '2002-01-01', 
              DATE '2002-12-31', 
              40000); 
END; 
/

SELECT * 
  FROM employees 
 WHERE salary = 40000 ;

