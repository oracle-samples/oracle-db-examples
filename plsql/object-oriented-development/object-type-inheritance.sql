/*
When you build hierarchies of object types, remember that attributes 
of parents are passed down to the subtypes. So when you call a constructor 
function for a subtype, you must include a value for all the attributes 
in the parent(s) as well.
*/

CREATE OR REPLACE TYPE food_ot AS OBJECT 
( 
   food_name VARCHAR2 (100), 
   food_group VARCHAR2 (50), 
   grown_in VARCHAR2 (100) 
) 
NOT FINAL; 
/

CREATE OR REPLACE TYPE dessert_ot 
   UNDER food_ot 
   ( 
      contains_chocolate CHAR (1), 
      year_created NUMBER (4) 
   ) 
   NOT FINAL; 
/

DECLARE 
   l_food   food_ot := food_ot ('Chocolate Cake', 'Sugar', 'Oven'); 
BEGIN 
   DBMS_OUTPUT.put_line (l_food.food_name); 
END; 
/

DECLARE 
   l_food   dessert_ot 
               := dessert_ot ('Chocolate Cake', 
                              'Sugar', 
                              'Oven', 
                              'Y', 
                              1492); 
BEGIN 
   DBMS_OUTPUT.put_line (l_food.food_name); 
END; 
/

DECLARE 
   l_food   dessert_ot := food_ot ('Chocolate Cake', 'Sugar', 'Oven'); 
BEGIN 
   DBMS_OUTPUT.put_line (l_food.food_name); 
END; 
/

DECLARE 
   l_food   dessert_ot := dessert_ot ('Y', 1492); 
BEGIN 
   DBMS_OUTPUT.put_line (l_food.food_name); 
END; 
/

DECLARE 
   l_food   food_ot 
               := dessert_ot ('Chocolate Cake', 
                              'Sugar', 
                              'Oven', 
                              'Y', 
                              1492); 
BEGIN 
   DBMS_OUTPUT.put_line (l_food.food_name); 
END; 
/

DECLARE 
   l_food   dessert_ot 
               := food_ot ('Chocolate Cake', 
                           'Sugar', 
                           'Oven', 
                           'Y', 
                           1492); 
BEGIN 
   DBMS_OUTPUT.put_line (l_food.food_name); 
END; 
/

