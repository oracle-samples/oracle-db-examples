/*
A table function is a function executed with the TABLE operator, 
and then within the FROM clause of a query - in other words, a function 
that is selected from just like a relational table! A common usage of 
table functions in the Data Warehousing world is to stream data directly 
from one process or transformation, to the next process without 
intermediate staging (a "streaming" table function). But you can also 
leverage table functions to programatically create a dataset and then 
make it available in SQL.
*/

-- Create Nested Table Type
/*
A table function must return a collection that is visible in the SQL layer. 
So the collection's type must be defined at the schema-level as shown here or 
in 12.1 and higher in a package specification.
*/

CREATE OR REPLACE TYPE names_nt IS TABLE OF VARCHAR2 ( 1000 ); 
/

-- Silly Dataset Generator
/*
I need to generated N number of names. Here's a function that does it. 
It's a silly example. I can do this in SQL, too, but it demonstrates the ability 
to programmatically (procedurally) populate a collection.
*/

CREATE OR REPLACE FUNCTION lotsa_names (  
   base_name_in   IN   VARCHAR2  
 , count_in       IN   INTEGER  
)  
   RETURN names_nt  
IS  
   retval names_nt := names_nt ( );  
BEGIN  
   retval.EXTEND ( count_in );  
  
   FOR indx IN 1 .. count_in  
   LOOP  
      retval ( indx ) := base_name_in || ' ' || indx;  
   END LOOP;  
  
   RETURN retval;  
END lotsa_names; 
/

-- Call table function inside SELECT  
/*
And there you have it, folks! Embed the function invocation inside the 
TABLE operator, in the FROM clause, and Oracle Database works its magic for you. 

And when you have a collection of scalars, the column name is hard-coded to 
COLUMN_VALUE but you can use a column alias to change it to whatever you'd like.
*/

SELECT COLUMN_VALUE my_name 
  FROM TABLE ( lotsa_names ( 'Steven', 100 )) names ;

-- A "Table" Just Like Any Other
/*
Once TABLE has transformed your collection into a relational dataset, 
you can join it to other tables, perform unions, etc. Whatever you would 
and could do with a "normal" table or view.
*/

SELECT COLUMN_VALUE my_alias  
  FROM hr.employees, TABLE ( lotsa_names ( 'Steven', 10 )) names ;

-- Return Cursor Variable to Dataset
/*
Here's an example of calling the table function, converting to a SQL dataset, 
assigning it to a cursor variable, and then returning that via the function. 
This function could then be invoked from a host environment, say a Java program, 
and the data will be consumed. That Java or UI developer will have no idea 
how the data set was constructed, and why should they care?
*/

CREATE OR REPLACE FUNCTION lotsa_names_cv (  
   base_name_in   IN   VARCHAR2  
 , count_in       IN   INTEGER  
)  
   RETURN sys_refcursor  
IS  
   retval sys_refcursor;  
BEGIN  
   OPEN retval FOR  
      SELECT COLUMN_VALUE  
        FROM TABLE ( lotsa_names ( base_name_in, count_in )) names;  
  
   RETURN retval;  
END lotsa_names_cv; 
/

DECLARE 
   l_names_cur sys_refcursor; 
   l_name VARCHAR2 ( 32767 ); 
BEGIN 
   l_names_cur := lotsa_names_cv ( 'Steven', 100 ); 
 
   LOOP 
      FETCH l_names_cur INTO l_name; 
 
      EXIT WHEN l_names_cur%NOTFOUND; 
      DBMS_OUTPUT.put_line ( 'Name = ' || l_name ); 
   END LOOP; 
 
   CLOSE l_names_cur; 
END; 
/

