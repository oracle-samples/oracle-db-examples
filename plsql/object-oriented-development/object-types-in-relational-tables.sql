/*
This script accompanies my blog post of the same title, part of a series on 
using the object-oriented features of Oracle PL/SQL (object types). 

This script focuses on how you can use object types inside relational tables,
either as an object type table (TABLE OF object_type) or as object type
columns within a "normal" relational table.

The link: https://stevenfeuersteinonplsql.blogspot.com/2019/10/using-object-types-in-relational-tables.html
*/

CREATE TYPE food_ot AS OBJECT 
( 
   name VARCHAR2 (100), 
   food_group VARCHAR2 (50), 
   grown_in VARCHAR2 (100) 
) 
   NOT FINAL 
/

CREATE TABLE food_table OF food_ot 
( 
   CONSTRAINT food_table_pk PRIMARY KEY (name) 
) ;

BEGIN 
   INSERT INTO food_table 
        VALUES (NEW food_ot ('Mutter Paneer', 'Curry', 'India')); 
 
   INSERT INTO food_table 
        VALUES (NEW food_ot ('Cantaloupe', 'Fruit', 'Backyard')); 
 
   COMMIT; 
END; 
/

SELECT * FROM food_table ;

BEGIN 
   UPDATE food_table 
      SET grown_in = 'Florida' 
    WHERE name = 'Cantaloupe'; 
END; 
/

SELECT * FROM food_table ;

SELECT ft.name 
  FROM food_table ft ;

CREATE OR REPLACE TYPE dessert_ot 
   UNDER food_ot 
   ( 
      contains_chocolate CHAR (1), 
      year_created NUMBER (4) 
   ) 
   NOT FINAL; 
/

CREATE OR REPLACE TYPE cake_ot 
   UNDER dessert_ot 
   ( 
      diameter NUMBER, 
      inscription VARCHAR2 (200) 
   ); 
/

CREATE TABLE meals 
( 
   served_on     DATE, 
   appetizer     food_ot, 
   main_course   food_ot, 
   dessert       dessert_ot 
);

BEGIN 
   -- Populate the meal table 
   INSERT INTO meals (served_on, appetizer, main_course, dessert) 
        VALUES (SYSDATE, 
                food_ot ('Shrimp cocktail', 'PROTEIN', 'Ocean'), 
                food_ot ('Eggs benedict', 'PROTEIN', 'Farm'), 
                dessert_ot ('Strawberries and cream', 
                            'FRUIT', 
                            'Backyard', 
                            'N', 
                            2001)); 
 
   INSERT INTO meals (served_on, appetizer, main_course, dessert) 
        VALUES (SYSDATE + 1, 
                food_ot ('House Salad', 'VEGETABLE', 'Farm'), 
                food_ot ('Stir fry tofu', 'PROTEIN', 'Vat'), 
                cake_ot ('Apple Pie', 
                         'FRUIT', 
                         'Baker''s Square', 
                         'N', 
                         2001, 
                         8, 
                         NULL)); 
 
   INSERT INTO meals (served_on, appetizer, main_course, dessert) 
        VALUES (SYSDATE + 1, 
                food_ot ('Fried Calamari', 'PROTEIN', 'Ocean'), 
                dessert_ot ('Butter cookie', 
                            'CARBOHYDRATE', 
                            'Oven', 
                            'N', 
                            2001), 
                cake_ot ('French Silk Pie', 
                         'CARBOHYDRATE', 
                         'Baker''s Square', 
                         'Y', 
                         2001, 
                         6, 
                         'To My Favorite Frenchman')); 
 
   INSERT INTO meals (served_on, appetizer, main_course, dessert) 
        VALUES (SYSDATE + 1, 
                NULL, 
                cake_ot ('French Silk Pie', 
                         'CARBOHYDRATE', 
                         'Baker''s Square', 
                         'Y', 
                         2001, 
                         6, 
                         'To My Favorite Frenchman'), 
                dessert_ot ('Butter cookie', 
                            'CARBOHYDRATE', 
                            'Oven', 
                            'N', 
                            2001)); 
END; 
/

BEGIN 
    INSERT INTO meals (served_on, appetizer, main_course, dessert) 
        VALUES (SYSDATE, 
                food_ot ('Shrimp cocktail', 'PROTEIN', 'Ocean'), 
                dessert_ot ('Strawberries and cream', 
                            'FRUIT', 
                            'Backyard', 
                            'N', 
                            2001), 
                food_ot ('Lollipop', 'SUGAR', 'Factory')); 
END; 
/

SELECT served_on FROM meals ;

SELECT served_on, NVL (m.appetizer.name, 'Not that hungry') appetizer  
  FROM meals ;

SELECT served_on, NVL (m.appetizer.name, 'Not that hungry') appetizer 
  FROM meals m ;

SELECT m.contains_chocolate 
  FROM meals m ;

SELECT m.served_on, 
       m.main_course.name 
  FROM meals m 
 WHERE TREAT (main_course AS dessert_ot) IS NOT NULL ;

SELECT main_course.contains_chocolate chocolatey 
  FROM meals 
 WHERE TREAT (main_course AS dessert_ot) IS NOT NULL ;

SELECT TREAT (main_course AS dessert_ot).contains_chocolate chocolatey, 
       TREAT (main_course AS dessert_ot).year_created 
  FROM meals 
 WHERE TREAT (main_course AS dessert_ot) IS NOT NULL ;

SELECT TREAT (main_course AS dessert_ot) dessert 
  FROM meals 
 WHERE TREAT (main_course AS dessert_ot) IS NOT NULL ;

SELECT m.dessert.name 
  FROM meals m 
 WHERE TREAT (main_course AS dessert_ot) IS NOT NULL ;

UPDATE meals 
   SET dessert = TREAT (dessert AS cake_ot) ;

SELECT m.dessert.name 
  FROM meals m 
 WHERE TREAT (main_course AS dessert_ot) IS NOT NULL ;

SELECT m.main_course.name 
  FROM meals m 
 ORDER BY main_course ;

