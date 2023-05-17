/*
As of Oracle Database 12c Release 1, you can now use the TABLE operator 
with associative arrays whose types are declared in a package specification. 
Prior to 12.1, this was only possible with schema-level nested table and varray types. 

What if you need to access the index values of that array in the dataset returned 
by the TABLE operator? That information simply isn't available natively - which, 
I think, is quite reasonable. When you use SELECT-FROM TABLE you are saying, 
in effect, I want to treat the data as a virtual tables. Tables don't have indexes 
built into them. You have to specify them "on top" of the table.

In any case, the solution isn't terribly difficult. You simply add a field to 
your record (or attribute to object type). Or if your collection is currently a 
collection of scalars (list of dates or strings or numbers), then you will have 
to create a record or object type to hold that scalar value, plus the index value. 
Then that index value is available as "just another column" in your query. 
*/

-- A Collection of Records
-- Yes, two user-defined, PL/SQL-specific types: a record and a collection of those records.
CREATE OR REPLACE PACKAGE aa_pkg AUTHID DEFINER  
IS  
   TYPE record_t IS RECORD  
      (nm VARCHAR2 (100), sal NUMBER);  
  
   TYPE array_t IS TABLE OF record_t INDEX BY PLS_INTEGER;  
  
   FUNCTION my_array RETURN array_t;  
END; 
/

-- Populate An Array for Easy Testing
-- I include a single function in the package to populate the collection. 
-- Removes "clutter" from the demonstration block(s) below.
CREATE OR REPLACE PACKAGE BODY aa_pkg  
IS  
   FUNCTION my_array  
      RETURN array_t  
   IS  
      l_return   array_t;  
   BEGIN  
      l_return (1).nm := 'Me';  
      l_return (1).sal := 1000;  
      l_return (200).nm := 'You';  
      l_return (200).sal := 2;  
  
      RETURN l_return;  
   END;  
END; 
/

-- Yes, Use TABLE with Associative Arrays of Records!
-- Just to confirm: this works on 12.1 and higher. Very nice....thanks, PL/SQL dev team!
DECLARE  
   l_array   aa_pkg.array_t;  
BEGIN  
   l_array := aa_pkg.my_array;  
  
   FOR rec IN (  SELECT * FROM TABLE (l_array) ORDER BY nm)  
   LOOP  
      DBMS_OUTPUT.put_line (rec.nm);  
   END LOOP;  
END; 
/

-- Add Index Value to Record Type
CREATE OR REPLACE PACKAGE aa_pkg AUTHID DEFINER  
IS  
   TYPE record_t IS RECORD  
   (  
      idx   INTEGER,  
      nm    VARCHAR2 (100),  
      sal   NUMBER  
   );  
  
   TYPE array_t IS TABLE OF record_t INDEX BY PLS_INTEGER;  
  
   FUNCTION my_array RETURN array_t;  
END; 
/

-- Same Package Body as Before
CREATE OR REPLACE PACKAGE BODY aa_pkg  
IS  
   FUNCTION my_array RETURN array_t  
   IS  
      l_return   array_t;  
   BEGIN  
      l_return (1).nm := 'Me';  
      l_return (1).sal := 1000;  
      l_return (-200).nm := 'You';  
      l_return (-200).sal := 2;  
  
      RETURN l_return;  
   END;  
END; 
/

-- Add Index Value to Records, Use in Query
-- I can order by the index value, reference it inside my PL/SQL code, and elsewhere in my query. 
DECLARE  
   l_array   aa_pkg.array_t;  
   l_index   PLS_INTEGER;  
BEGIN  
   l_array := aa_pkg.my_array;  
   l_index := l_array.FIRST;  
  
   WHILE l_index IS NOT NULL  
   LOOP  
      l_array (l_index).idx := l_index;  
      l_index := l_array.next (l_index);  
   END LOOP;  
  
   FOR rec IN (  SELECT * FROM TABLE (l_array) ORDER BY idx)  
   LOOP  
      DBMS_OUTPUT.put_line (rec.idx || ' = ' || rec.nm);  
   END LOOP;  
END; 
/

