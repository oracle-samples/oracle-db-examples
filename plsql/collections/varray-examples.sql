/*
The varray (variable size array) is one of the three types of collections in PL/SQL 
(associative array, nested table, varray). The varray's key distinguishing feature 
is that when you declare a varray type, you specify the maximum number of elements 
that can be defined in the varray. Yes, it is odd that the collection with any 
sense of a "fixed" maximum size is called the "variable size" array. But hey! 
More information: http://docs.oracle.com/database/121/LNPLS/composites.htm#LNPLS443
*/

-- Create Schema-Level Type
-- You can define a varray type at the schema level of within a PL/SQL 
-- declaration section. This one can have no more than 10 elements.
CREATE OR REPLACE TYPE list_of_names_t IS  
   VARRAY(10) OF VARCHAR2 (100); 
/

-- Let Others Use Your Type
-- You grant EXECUTE to give other schemas access to your schema-level type.
GRANT EXECUTE ON list_of_names_t TO PUBLIC 


-- All The Usual Methods
-- You can use EXTEND to make room in the varray for new elements, use COUNT, FIRST, LAST, etc., except...
DECLARE  
   happyfamily   list_of_names_t := list_of_names_t ();  
BEGIN  
   happyfamily.EXTEND (4);  
   happyfamily (1) := 'Eli';  
   happyfamily (2) := 'Steven';  
   happyfamily (3) := 'Chris';  
   happyfamily (4) := 'Veva';  
     
   FOR l_row IN 1 .. happyfamily.COUNT  
   LOOP  
      DBMS_OUTPUT.put_line (happyfamily (l_row));  
   END LOOP;  
END; 
/

-- Limitations on DELETE with Varray
/*
Varrays always have consecutive subscripts, so you cannot delete individual 
elements except from the end by using the TRIM method. You can use DELETE without 
parameters to delete all elements. So this block fails.
*/
DECLARE  
   happyfamily   list_of_names_t := list_of_names_t ();  
BEGIN  
   happyfamily.EXTEND (4);  
   happyfamily (1) := 'Eli';  
   happyfamily (2) := 'Steven';  
   happyfamily (3) := 'Chris';  
   happyfamily (4) := 'Veva';  
     
   happyfamily.delete (2);  
END; 
/

-- Use TABLE Operator with Varray
-- You can apply SQL query logic to the contents a varray using the TABLE operator.
DECLARE  
   happyfamily   list_of_names_t := list_of_names_t ();  
 BEGIN  
   happyfamily.EXTEND (4);  
   happyfamily (1) := 'Eli';  
   happyfamily (2) := 'Steven';  
   happyfamily (3) := 'Chris';  
   happyfamily (4) := 'Veva';  
    
   /* Use TABLE operator to apply SQL operations to  
      a PL/SQL nested table */  
  
   FOR rec IN (  SELECT COLUMN_VALUE family_name  
                   FROM TABLE (happyfamily)  
               ORDER BY family_name)  
   LOOP  
      DBMS_OUTPUT.put_line (rec.family_name);  
   END LOOP;  
END; 
/

-- Varray as Column Type in Database
-- You can define a column of varray type in a relational table. The next several steps demonstrate this.
CREATE OR REPLACE TYPE parent_names_t IS VARRAY (2) OF VARCHAR2 (100); 
/

-- Silly Varray!
-- Can you see why this is a silly use of a varray?
CREATE OR REPLACE TYPE child_names_t IS VARRAY (1) OF VARCHAR2 (100); 
/

CREATE TABLE family 
( 
   surname          VARCHAR2 (1000) 
 , parent_names     parent_names_t 
 , children_names   child_names_t 
) ;

-- Insert Varrays into Table
-- Use native INSERT statement. So easy!
DECLARE  
   parents    parent_names_t := parent_names_t ();  
   children   child_names_t := child_names_t ();  
BEGIN  
   DBMS_OUTPUT.put_line (parents.LIMIT);  
     
   parents.EXTEND (2);  
   parents (1) := 'Samuel';  
   parents (2) := 'Charina';  
   --  
   children.EXTEND;  
   children (1) := 'Feather';  
  
   --  
   INSERT INTO family (surname, parent_names, children_names)  
        VALUES ('Assurty', parents, children);  
  
   COMMIT;  
END; 
/

SELECT * FROM family ;



-- Modify Limit on Existing Varray

CREATE OR REPLACE TYPE names_vat AS VARRAY (10) OF VARCHAR2 (80); 
/

DECLARE 
   l_list   names_vat := names_vat (); 
BEGIN 
   DBMS_OUTPUT.put_line ('Limit of names_vat = ' || l_list.LIMIT); 
END; 
/

-- Modify Limit on Existing Varray
ALTER TYPE names_vat MODIFY LIMIT 100 INVALIDATE ;

DECLARE 
   l_list   names_vat := names_vat (); 
BEGIN 
   DBMS_OUTPUT.put_line ('Limit of names_vat = ' || l_list.LIMIT); 
END; 
/

-- Modify Limit on Existing Varray with Dynamic SQL
BEGIN 
   EXECUTE IMMEDIATE 'ALTER TYPE names_vat MODIFY LIMIT 200 INVALIDATE'; 
END; 
/

DECLARE 
   l_list   names_vat := names_vat (); 
BEGIN 
   DBMS_OUTPUT.put_line ('Limit of names_vat = ' || l_list.LIMIT); 
END; 
/



