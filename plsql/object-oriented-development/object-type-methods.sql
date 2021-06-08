/*
This script explores member methods and the SELF value, static methods, 
non-instantiable methods and how invoke a supertype's method explicitly. 
This code is fully explained in the accompanying blog post at 

https://stevenfeuersteinonplsql.blogspot.com/2019/09/plsql-101-static-and-member-methods-of.html 
*/

CREATE OR REPLACE TYPE food_ot AS OBJECT ( 
   name VARCHAR2 (100), 
   food_group VARCHAR2 (50), 
   grown_in VARCHAR2 (100), 
   MEMBER FUNCTION to_string RETURN VARCHAR2 
) 
NOT FINAL; 
/

CREATE OR REPLACE TYPE BODY food_ot 
IS 
   MEMBER FUNCTION to_string RETURN VARCHAR2 
   IS 
   BEGIN 
      RETURN    'FOOD! ' 
             || SELF.NAME 
             || ' - ' 
             || SELF.food_group 
             || ' - ' 
             || SELF.grown_in; 
   END; 
END; 
/

DECLARE 
   squirrels_love_them  food_ot :=  
      food_ot ('Acorn', 'Protein', 'Tree'); 
BEGIN 
   DBMS_OUTPUT.put_line (squirrels_love_them.to_string()); 
END; 
/

CREATE OR REPLACE TYPE food_ot AS OBJECT ( 
   name VARCHAR2 (100), 
   food_group VARCHAR2 (50), 
   grown_in VARCHAR2 (100), 
   MEMBER FUNCTION to_string (SELF IN food_ot) RETURN VARCHAR2 
) 
NOT FINAL; 
/

CREATE OR REPLACE TYPE BODY food_ot 
IS 
   MEMBER FUNCTION to_string (SELF IN food_ot) RETURN VARCHAR2 
   IS 
   BEGIN 
      RETURN    'FOOD! ' 
             || SELF.NAME 
             || ' - ' 
             || SELF.food_group 
             || ' - ' 
             || SELF.grown_in; 
   END; 
END; 
/

DECLARE 
   squirrels_love_them  food_ot :=  
      food_ot ('Acorn', 'Protein', 'Tree'); 
BEGIN 
   DBMS_OUTPUT.put_line (squirrels_love_them.to_string()); 
END; 
/

CREATE OR REPLACE TYPE food_ot AS OBJECT ( 
   name VARCHAR2 (100), 
   food_group VARCHAR2 (50), 
   grown_in VARCHAR2 (100), 
   MEMBER FUNCTION to_string (SELF IN OUT food_ot) RETURN VARCHAR2 
) 
NOT FINAL; 
/

CREATE OR REPLACE TYPE BODY food_ot 
IS 
   MEMBER FUNCTION to_string (SELF IN OUT food_ot) RETURN VARCHAR2 
   IS 
   BEGIN 
      /* Enforce upper case for all values */ 
      SELF.name := UPPER (SELF.name); 
      SELF.food_group := UPPER (SELF.food_group); 
      SELF.grown_in := UPPER (SELF.grown_in); 
       
      RETURN    'FOOD! ' 
             || SELF.NAME 
             || ' - ' 
             || SELF.food_group 
             || ' - ' 
             || SELF.grown_in; 
   END; 
END; 
/

DECLARE 
   squirrels_love_them  food_ot :=  
      food_ot ('Acorn', 'Protein', 'Tree'); 
BEGIN 
   DBMS_OUTPUT.put_line (squirrels_love_them.to_string()); 
   DBMS_OUTPUT.put_line ('Still upper case? ' || squirrels_love_them.name); 
END; 
/

CREATE OR REPLACE TYPE food_ot AS OBJECT 
( 
   name VARCHAR2 (100), 
   food_group VARCHAR2 (50), 
   grown_in VARCHAR2 (100), 
   STATIC FUNCTION version RETURN VARCHAR2 
) 
   NOT FINAL; 
/

CREATE OR REPLACE TYPE BODY food_ot 
IS 
   STATIC FUNCTION version RETURN VARCHAR2 
   IS 
   BEGIN 
      /*  
      Version history 
      2018-09-14 1.0.1 Type deployed to production 
      2019-03-22 1.0.2 Added grown_in attribute       
      */ 
      RETURN '1.0.2'; 
   END; 
END; 
/

BEGIN 
   DBMS_OUTPUT.put_line (food_ot.version); 
END; 
/

CREATE OR REPLACE TYPE dessert_ot UNDER food_ot ( 
    contains_chocolate CHAR (1) 
  , year_created NUMBER (4)  
); 
/

BEGIN 
   DBMS_OUTPUT.put_line (dessert_ot.version); 
END; 
/

CREATE OR REPLACE TYPE dessert_ot UNDER food_ot ( 
    contains_chocolate CHAR (1) 
  , year_created NUMBER (4)  
  , OVERRIDING STATIC FUNCTION version RETURN VARCHAR2 
); 
/

CREATE OR REPLACE TYPE dessert_ot UNDER food_ot ( 
    contains_chocolate CHAR (1) 
  , year_created NUMBER (4)  
  , STATIC FUNCTION version RETURN VARCHAR2 
); 
/

CREATE OR REPLACE TYPE BODY dessert_ot 
IS 
   STATIC FUNCTION version RETURN VARCHAR2 
   IS 
   BEGIN 
      RETURN 'v10.4.5'; 
   END; 
END; 
/

BEGIN 
   DBMS_OUTPUT.put_line (dessert_ot.version); 
END; 
/

CREATE OR REPLACE TYPE dessert_ot UNDER food_ot ( 
    contains_chocolate CHAR (1) 
  , year_created NUMBER (4)  
  , STATIC PROCEDURE version  
); 
/

CREATE OR REPLACE TYPE BODY dessert_ot 
IS 
   STATIC PROCEDURE version  
   IS 
   BEGIN 
      DBMS_OUTPUT.PUT_LINE ('v10.4.5'); 
   END; 
END; 
/

BEGIN 
   DBMS_OUTPUT.put_line (dessert_ot.version); 
   dessert_ot.version; 
END; 
/

DROP TYPE dessert_ot FORCE ;

DROP TYPE dessert_ot FORCE
/

-- You cannot use the constructor of a non-instantiable type, but you can use the constructor of a subtype!
CREATE OR REPLACE TYPE food_ot AS OBJECT ( 
   name VARCHAR2 (100), 
   NOT INSTANTIABLE MEMBER FUNCTION price 
      RETURN NUMBER 
) 
NOT FINAL NOT INSTANTIABLE; 
/

CREATE OR REPLACE TYPE dessert_ot UNDER food_ot ( 
   contains_chocolate   CHAR (1)
 , OVERRIDING MEMBER FUNCTION price 
      RETURN NUMBER 
) 
NOT FINAL;
/

CREATE OR REPLACE TYPE BODY dessert_ot 
IS 
   OVERRIDING MEMBER FUNCTION price 
      RETURN NUMBER 
   IS 
   BEGIN 
      RETURN 1; 
   END; 
END; 
/

DECLARE 
   l_food food_ot ; 
BEGIN 
   l_food := dessert_ot ('Apple', 'N'); 
   DBMS_OUTPUT.PUT_LINE (l_food.name); 
END; 
/


CREATE OR REPLACE TYPE food_ot AS OBJECT ( 
   name VARCHAR2 (100), 
   food_group VARCHAR2 (50), 
   grown_in VARCHAR2 (100), 
   -- Generic foods cannot have a price, but we can 
   -- insist that all subtypes DO implement a price 
   -- function. 
   NOT INSTANTIABLE MEMBER FUNCTION price 
      RETURN NUMBER 
) 
NOT FINAL NOT INSTANTIABLE; 
/

DECLARE 
   l_food food_ot := food_ot ('a', 'b', 'c'); 
BEGIN 
   DBMS_OUTPUT.PUT_LINE (l_food.name); 
END; 
/

CREATE OR REPLACE TYPE dessert_ot UNDER food_ot ( 
   contains_chocolate   CHAR (1) 
 , year_created         NUMBER (4) 
 , OVERRIDING MEMBER FUNCTION price 
      RETURN NUMBER 
) 
NOT FINAL; 
/

CREATE OR REPLACE TYPE BODY dessert_ot 
IS 
   OVERRIDING MEMBER FUNCTION price 
      RETURN NUMBER 
   IS 
      multiplier   NUMBER := 1; 
   BEGIN 
      DBMS_OUTPUT.put_line ('Dessert price!'); 
 
      IF SELF.contains_chocolate = 'Y' 
      THEN 
         multiplier := 2; 
      END IF; 
 
      IF SELF.year_created < 1900 
      THEN 
         multiplier := multiplier + 0.5; 
      END IF; 
 
      RETURN (10.00 * multiplier); 
   END; 
END; 
/

DECLARE 
   l_apple dessert_ot := dessert_ot ('Apple', 'Fruit', 'Tree', 'N', -5000); 
BEGIN 
   DBMS_OUTPUT.PUT_LINE (l_apple.name); 
END; 
/

DROP type dessert_ot force ;

CREATE OR REPLACE TYPE food_ot AS OBJECT ( 
   name VARCHAR2 (100), 
   food_group VARCHAR2 (50), 
   grown_in VARCHAR2 (100), 
   MEMBER FUNCTION to_string 
      RETURN VARCHAR2 
) 
NOT FINAL; 
/

CREATE OR REPLACE TYPE BODY food_ot 
IS 
   MEMBER FUNCTION to_string 
      RETURN VARCHAR2 
   IS 
   BEGIN 
      RETURN    'FOOD! ' 
             || SELF.NAME 
             || ' - ' 
             || SELF.food_group 
             || ' - ' 
             || SELF.grown_in; 
   END; 
END; 
/

CREATE OR REPLACE TYPE dessert_ot UNDER food_ot ( 
    contains_chocolate CHAR (1) 
  , year_created NUMBER (4)  
  , OVERRIDING MEMBER FUNCTION to_string RETURN VARCHAR2 
); 
/

CREATE OR REPLACE TYPE BODY dessert_ot 
IS 
   OVERRIDING MEMBER FUNCTION to_string  RETURN VARCHAR2 
   IS 
   BEGIN 
      /* Add the supertype (food) string to the subtype string.... */ 
      RETURN    'DESSERT! With Chocolate? ' 
             || contains_chocolate 
             || ' created in ' 
             || SELF.year_created 
             || chr(10) 
             || '...which is a...' 
             || (SELF as food_ot).to_string; 
   END; 
END; 
/

DECLARE 
   TYPE foodstuffs_nt IS TABLE OF food_ot; 
 
   fridge_contents foodstuffs_nt 
         := foodstuffs_nt ( 
               food_ot ('Eggs benedict', 'PROTEIN', 'Farm') 
             , dessert_ot ('Strawberries and cream' 
                        , 'FRUIT', 'Backyard', 'N', 2001) 
            ); 
BEGIN 
   FOR indx in 1 .. fridge_contents.COUNT 
   LOOP 
      DBMS_OUTPUT.put_line (RPAD ('=', 60, '=')); 
      DBMS_OUTPUT.put_line (fridge_contents (indx).to_string); 
   END LOOP; 
END; 
/

