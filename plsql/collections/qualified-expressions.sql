/*
Aggregates and their necessary adjunct, qualified expressions, improve program clarity and programmer productivity. Through Oracle Database 12c release 2, it was possible to supply the value of a non-scalar datatype with an expression, for example by using the type constructor for a nested table. Starting with Oracle Database Release 18c, any PL/SQL value can be provided by an expression (for example for a record or for an associative array) like a constructor provides an abstract datatype value. 

In PL/SQL, we use the terms "qualified expression" and "aggregate" rather than the SQL term "type constructor", but the functionality is the same. Qualified expressions improve program clarity and developer productivity by providing the ability to declare and define a complex value in a compact form where the value is needed. 

A qualified expression combines expression elements to create values of a RECORD type or associative array type. Qualified expressions use an explicit type indication to provide the type of the qualified item. This explicit indication is known as a typemark. 
*/

-- Before 18c
-- You either had to write your own function to populate the collection or write 
-- individual assignments in the executable section.
DECLARE   
   TYPE ints_t IS TABLE OF INTEGER   
      INDEX BY PLS_INTEGER;   
   
   l_ints   ints_t;   
BEGIN   
   l_ints (1) := 55;  
   l_ints (2) := 555;  
   l_ints (3) := 5555;  
  
   FOR indx IN 1 .. l_ints.COUNT   
   LOOP   
      DBMS_OUTPUT.put_line (l_ints (indx));   
   END LOOP;   
END;
/

-- And Now...Ahhhhhh....
-- So much nice and oh so flexible!
DECLARE  
   TYPE ints_t IS TABLE OF INTEGER  
      INDEX BY PLS_INTEGER;  
  
   l_ints   ints_t := ints_t (1 => 55, 2 => 555, 3 => 5555);  
BEGIN  
   FOR indx IN 1 .. l_ints.COUNT  
   LOOP  
      DBMS_OUTPUT.put_line (l_ints (indx));  
   END LOOP;  
END;
/

-- You MUST specify the index value in the list of elements for the array construction.
DECLARE 
   TYPE ints_t IS TABLE OF INTEGER 
      INDEX BY PLS_INTEGER; 
 
   l_ints   ints_t := ints_t (55, 555, 5555); 
BEGIN 
   DBMS_OUTPUT.PUT_LINE (l_ints.COUNT); 
END;
/

DECLARE
   TYPE ints_t IS TABLE OF INTEGER
      INDEX BY PLS_INTEGER;

   l_ints   ints_t := ints_t (2 => 555, 1 => 55, 3 => 5555);
BEGIN
   FOR indx IN 1 .. l_ints.COUNT
   LOOP
      DBMS_OUTPUT.put_line (l_ints (indx));
   END LOOP;
END;
/

DECLARE
   TYPE ints_t IS TABLE OF INTEGER
      INDEX BY PLS_INTEGER;

   l_ints   ints_t := ints_t (600 => 55, -5 => 555, 200000 => 5555);
   l_index pls_integer := l_ints.first;
BEGIN
   WHILE l_index IS NOT NULL
   LOOP
      DBMS_OUTPUT.put_line (l_index || ' => ' || l_ints (l_index));
      l_index := l_ints.NEXT (l_index);
   END LOOP;
END;
/

DECLARE
   TYPE ints_t IS TABLE OF INTEGER
      INDEX BY PLS_INTEGER;

   l_ints   ints_t;
   l_index  INTEGER;
BEGIN
   l_ints := ints_t (600 => 55, -5 => 555, 200000 => 5555);
   
   l_index := l_ints.first;
   
   WHILE l_index IS NOT NULL
   LOOP
      DBMS_OUTPUT.put_line (l_index || ' => ' || l_ints (l_index));
      l_index := l_ints.NEXT (l_index);
   END LOOP;
END;
/

DECLARE
   TYPE species_rt IS RECORD
   (
      species_name VARCHAR2 (100),
      habitat_type VARCHAR2 (100),
      surviving_population INTEGER
   );
   
   TYPE species_t IS TABLE OF species_rt
      INDEX BY PLS_INTEGER;

   l_species   species_t := 
      species_t (
         2 => species_rt ('Elephant', 'Savannah', '10000'), 
         1 => species_rt ('Dodos', 'Mauritius', '0'), 
         3 => species_rt ('Venus Flytrap', 'North Carolina', '250'));
BEGIN
   FOR indx IN 1 .. l_species.COUNT
   LOOP
      DBMS_OUTPUT.put_line (l_species (indx).species_name);
   END LOOP;
END;
/

-- Exact Same Type Must Be Used
DECLARE 
   TYPE species_rt IS RECORD 
   ( 
      species_name VARCHAR2 (100), 
      habitat_type VARCHAR2 (100), 
      surviving_population INTEGER 
   ); 
    
   TYPE species_t1 IS TABLE OF species_rt 
      INDEX BY PLS_INTEGER; 
    
   TYPE species_t2 IS TABLE OF species_rt 
      INDEX BY PLS_INTEGER; 
 
   l_species   species_t1 :=  
      species_t2 ( 
         1 => species_rt ('Elephant', 'Savannah', '10000')); 
BEGIN 
   NULL; 
END;
/

-- Qualified Expressions for String-Indexed Arrays
DECLARE 
   TYPE by_string_t IS TABLE OF INTEGER 
      INDEX BY VARCHAR2(100); 
 
   l_stuff   by_string_t := by_string_t ('Steven' => 55, 'Loey' => 555, 'Juna' => 5555); 
   l_index varchar2(100) := l_stuff.first; 
BEGIN 
   DBMS_OUTPUT.put_line (l_stuff.count); 
    
   WHILE l_index IS NOT NULL 
   LOOP 
      DBMS_OUTPUT.put_line (l_index || ' => ' || l_stuff (l_index)); 
      l_index := l_stuff.NEXT (l_index); 
   END LOOP; 
END;
/

DECLARE
   TYPE by_string_t IS TABLE OF INTEGER
      INDEX BY VARCHAR2 (100);

   l_stuff   by_string_t := 
      by_string_t (UPPER ('Grandpa Steven') => 55, 
                   'Loey'||'Juna' => 555, 
                   SUBSTR ('Happy Family', 7) => 5555);
   l_index varchar2(100) := l_stuff.first;
BEGIN
   DBMS_OUTPUT.put_line (l_stuff.count);

   WHILE l_index IS NOT NULL
   LOOP
      DBMS_OUTPUT.put_line (l_index || ' => ' || l_stuff (l_index));
      l_index := l_stuff.NEXT (l_index);
   END LOOP;
END;
/

