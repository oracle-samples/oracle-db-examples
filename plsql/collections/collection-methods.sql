/*
In this script, I demonstrate most of the methods available for PL/SQL collections, 
including COUNT, FIRST, LAST, NEXT, PRIOR, DELETE. 
*/

-- Set Up Collection
-- Rather than declare and populate a collection in each step, I declare 
-- a package-level type and variable, and fill it up. Since the variable is 
-- declared at the package level, it has session scope and persistence.
CREATE OR REPLACE PACKAGE methods_data 
IS 
   TYPE names_t IS TABLE OF VARCHAR2 (100); 
 
   my_family   names_t 
                  := names_t ('Veva', 
                              'Chris', 
                              'Eli', 
                              'Lauren', 
                              'Loey', 
                              'Juna', 
                              'Steven'); 
END;
/

-- Delete One Element
-- Pass a single value to DELETE and the element at that index value is removed - if it exists.
BEGIN 
   methods_data.my_family.DELETE (3); 
END;
/

-- Use EXISTS to See if Element is Defined
/*
If you try to "touch" an element at an undefined index value, PL/SQL 
raises NO_DATA_FOUND. If you want to avoid this problem, check first to see 
if the index value is defined with the EXISTS method.
*/
BEGIN 
   IF methods_data.my_family.EXISTS (2) 
   THEN 
      DBMS_OUTPUT.put_line (methods_data.my_family (2)); 
   END IF; 
 
   BEGIN 
      DBMS_OUTPUT.put_line (methods_data.my_family (3)); 
   EXCEPTION 
      WHEN NO_DATA_FOUND 
      THEN 
         DBMS_OUTPUT.put_line ('That''s why we have EXISTS!'); 
   END; 
 
   IF NOT methods_data.my_family.EXISTS (3) 
   THEN 
      DBMS_OUTPUT.put_line ('No name at index 3!'); 
   END IF; 
END;
/

-- Delete a Range of Values
-- Remove from the collection all elements between index values 5 and 7.
BEGIN 
   methods_data.my_family.DELETE (5, 7); 
END;
/

-- COUNT Shows You the, Ahem, Count
-- COUNT tells you how many elements are in the collection, returns 0 if empty. 
-- It does not count undefined index values between FIRST and LAST.
BEGIN 
   DBMS_OUTPUT.put_line ( 
      'Count left = ' || methods_data.my_family.COUNT); 
END;
/

-- Empty Entire Collection
-- Pass no arguments to DELETE and the collection is emptied of all elements.
BEGIN 
   methods_data.my_family.DELETE; 
 
   DBMS_OUTPUT.put_line ( 
      'Count left = ' || methods_data.my_family.COUNT); 
END;
/

-- Rebuild Collection
/*
It was set up by the package initialization. Let's get it back to that former 
state with a direct assignment, using the constructor function. This writes over 
whatever was in there before.
*/
BEGIN 
   methods_data.my_family := 
      methods_data.names_t ('Veva', 
               'Chris', 
               'Eli', 
               'Lauren', 
               'Loey', 
               'Juna', 
               'Steven'); 
END;
/

-- Navigation Methods: FIRST, LAST, NEXT, PRIOR
/*
FIRST gives you the lowest defined index value, LAST gives you the highest. 
NEXT takes you to the next defined index value ("skipping" over any undefined 
values in between). PRIOR takes to the previous defined index value. NEXT from 
LAST is always NULL. PRIOR from FIRST is always NULL.
*/

BEGIN 
   DBMS_OUTPUT.put_line ( 
      'First = ' || methods_data.my_family.FIRST); 
 
   DBMS_OUTPUT.put_line ( 
      'Last = ' || methods_data.my_family.LAST); 
 
   DBMS_OUTPUT.put_line ( 
      'Next from 3 = ' || methods_data.my_family.NEXT (3)); 
 
   DBMS_OUTPUT.put_line ( 
         'Next from last = ' 
      || NVL ( 
            TO_CHAR (methods_data.my_family.NEXT ( 
                       methods_data.my_family.LAST)), 
            'Not a thing')); 
 
   methods_data.my_family.delete (2); 
 
   DBMS_OUTPUT.put_line ( 
         'Prior from 3 (with 2 deleted) = ' 
      || methods_data.my_family.PRIOR (3)); 
 
   DBMS_OUTPUT.put_line ( 
         'Prior from first = ' 
      || NVL ( 
            TO_CHAR (methods_data.my_family.PRIOR ( 
                        methods_data.my_family.FIRST)), 
            'Not a thing')); 
END;
/

-- EXTEND Adds to Collection
-- Use EXTEND to add elements to the end of a collection (note: this is only 
-- for nested tables and varrays). Pass no arguments, and a single element is added.
BEGIN 
   methods_data.my_family.EXTEND; 
   DBMS_OUTPUT.put_line ( 
      'Last = ' || methods_data.my_family.LAST); 
END;
/

-- Extend Multiple Elements
/*
Pass a single argument to EXTEND and that number of elements are added. 
If you know you will be adding N elements, do it with a single call, rather 
than repeated calls to EXTEND in, say, a loop.
*/
BEGIN 
   methods_data.my_family.EXTEND (5); 
   DBMS_OUTPUT.put_line ( 
      'Last = ' || methods_data.my_family.LAST); 
END;
/

-- Rebuild Collection
BEGIN 
   methods_data.my_family := 
      methods_data.names_t ('Veva', 
               'Chris', 
               'Eli', 
               'Lauren', 
               'Loey', 
               'Juna', 
               'Steven'); 
END;
/

-- Extend with Copy
-- If you pass a second argument to EXTEND, then all the new elements added 
-- are assigned the value found in that specified index value.
BEGIN 
   methods_data.my_family.EXTEND (10, 2); 
 
   FOR indx IN 1 .. methods_data.my_family.COUNT 
   LOOP 
      DBMS_OUTPUT.put_line (methods_data.my_family (indx)); 
   END LOOP; 
END;
/

