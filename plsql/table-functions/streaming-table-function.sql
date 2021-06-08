/*
What is a streaming table function? Well, first, a table function is a 
function executed with the TABLE operator, and then within the FROM 
clause of a query - in other words, a function that is selected from 
just like a relational table! A common usage of table functions in the 
Data Warehousing world is to stream data directly from one process or 
transformation, to the next process without intermediate staging. 
Hence, a table function used in this way is called a streaming table function. 
For more details, check out my blog post: 

http://stevenfeuersteinonplsql.blogspot.com/2015/06/table-functions-part-4-streaming-table.html
*/

-- Daily Record of Stock Activity
-- This table records the day on which trading took place, the ticker symbol, 
-- and the open and close prices. 
CREATE TABLE daily_record  
(  
   ticker        VARCHAR2 (20),  
   trade_date    DATE,  
   open_price    NUMBER,  
   close_price   NUMBER  
) ;

-- Extremely Valuable Stocks
-- After all, humans cannot survive without chickpeas, broccoli and, most necessary of all, CHOCOLATE!
BEGIN  
   -- Populate the table.  
   INSERT INTO daily_record  
        VALUES ('CHICKPEAS',  
                trunc (SYSDATE),  
                10,  
                12);  
  
   INSERT INTO daily_record  
        VALUES ('BROCCOLI',  
                trunc (SYSDATE),  
                75,  
                87);  
  
   INSERT INTO daily_record  
        VALUES ('CHOCOLATE',  
                trunc (SYSDATE),  
                500,  
                2000);  
  
   COMMIT;  
END; 
/

-- Table of Open and Close Prices
/*
The daily record's OK, but we really want to separate out those open 
and close prices into separate rows - essentially do a very simple pivot of data. 
Now, as I am sure many of you know, you do NOT need PL/SQL and the added 
complexity of a table function to achieve this pivot. INSERT ALL will do 
just fine, for example. So assume for the purposes of this demonstration 
that the pivot logic is complex and needs procedural logic to get the job done.
*/

CREATE TABLE open_and_close  
(  
   ticker      VARCHAR2 (20),  
   pricedate   DATE,  
   pricetype   VARCHAR2 (1),  
   price       NUMBER  
) ;

-- An Object Type Mimicking the Table
/*
Table functions returns collections, in our case a nested table. Each element 
in the nested table will need to match the structure of the open_and_close table. 
I cannot, however, create a schema-level nested table like this 
"CREATE TYPE nt AS TABLE OF table%ROWTYPE". %ROWTYPE is syntax known only to 
PL/SQL, not SQL. So I will instead create an object type that mimics the relational table.
*/

CREATE TYPE open_and_close_ot AS OBJECT  
(  
   ticker VARCHAR2 (20),  
   pricedate DATE,  
   pricetype VARCHAR2 (1),  
   price NUMBER  
); 
/

-- Create Nested Table On Object Type
-- And now I create the nested table that will be returned by the table function 
-- as a collection of those object types.
CREATE TYPE open_and_close_nt AS TABLE OF open_and_close_ot; 
/

-- Package with Table Function
/*
My package specification holds two elements: the definition of the REF CURSOR 
that will be used to pass in the cursor variable to the function, and the header 
of the function. It takes in a dataset and a limit value (used by BULK COLLECT - 
better than hard-coding it!), and returns a nested table, with each row of 
daily_record broken out into two elements in the nested table.
*/

CREATE OR REPLACE PACKAGE stock_mgr 
IS 
   TYPE dailies_cur IS REF CURSOR 
      RETURN daily_record%ROWTYPE; 
 
   FUNCTION separate_dailies (dataset_in      dailies_cur, 
                              limit_in     IN INTEGER DEFAULT 100) 
      RETURN open_and_close_nt; 
END; 
/

-- The Table Function Definition
/*
Where all the magic happens. Of course, most of the magic will be the code 
you write to implement your specific transformation. In this case it is rather 
trivial. But the basic steps are: inside a loop, fetch the next N rows from the 
dataset using BULK COLLECT; execute the transformation logic; put the transformed 
data into the nested table; close the cursor when done; return the nested table.
*/

CREATE OR REPLACE PACKAGE BODY stock_mgr 
IS 
   FUNCTION separate_dailies (dataset_in      dailies_cur, 
                              limit_in     IN INTEGER DEFAULT 100) 
      RETURN open_and_close_nt 
   IS 
      TYPE dataset_tt IS TABLE OF daily_record%ROWTYPE 
         INDEX BY PLS_INTEGER; 
 
      l_dataset     dataset_tt; 
      l_separated   open_and_close_nt := open_and_close_nt (); 
   BEGIN 
      LOOP 
         FETCH dataset_in BULK COLLECT INTO l_dataset LIMIT limit_in; 
 
         EXIT WHEN l_dataset.COUNT = 0; 
 
         l_separated.EXTEND (l_dataset.COUNT * 2); 
 
         FOR indx IN 1 .. l_dataset.COUNT 
         LOOP 
            l_separated ( (indx - 1) * 2 + 1) := 
               open_and_close_ot (l_dataset (indx).ticker, 
                                  l_dataset (indx).trade_date, 
                                  'O', 
                                  l_dataset (indx).open_price); 
 
            l_separated ( (indx - 1) * 2 + 2) := 
               open_and_close_ot (l_dataset (indx).ticker, 
                                  l_dataset (indx).trade_date, 
                                  'C', 
                                  l_dataset (indx).close_price); 
         END LOOP; 
      END LOOP; 
 
      CLOSE dataset_in; 
 
      RETURN l_separated; 
   END; 
END; 
/

-- Execute Function in FROM Clause
/*
If this is the first time you are seeing a table function, pretty cool, 
right? You can call the function right inside the FROM clause of a SELECT - 
as long as you put it inside the TABLE operator. Furthermore, I use the CURSOR 
expression to convert a dataset - another SELECT, and not a dynamic one; 
it's not inside single quotes - into a cursor variable, which is then passed 
to the function! Notice that I include an ORDER BY. You would expect the 
data to be displayed exactly as it was put into the table, but you should not 
ASSUME nor RELY on that. If you want to be sure of the order of data displayed, 
you must always add an ORDER BY clause.
*/

SELECT *  
  FROM TABLE (stock_mgr.separate_dailies ( 
                 CURSOR (SELECT * FROM daily_record)))  
ORDER BY ticker, pricedate, pricetype;

