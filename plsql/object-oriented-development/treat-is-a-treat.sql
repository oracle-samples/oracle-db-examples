/*
Use TREAT to "downcast" an object type instance to a specific child type. 
That way, you can reference attributes of a subtype's instance, even when 
that instance is stored in a column based on a super type.
*/

-- Create a Hierarchy of Types
CREATE TYPE food_t AS OBJECT ( 
   name VARCHAR2(100), 
   food_group  VARCHAR2 (100), 
   grown_in    VARCHAR2 (100) 
   ) 
   NOT FINAL 
   ;
/

-- Every Dessert is a Food
-- But not every food is a dessert.
CREATE TYPE dessert_t UNDER food_t ( 
   contains_chocolate    CHAR(1), 
   year_created          NUMBER(4) 
   ) 
   NOT FINAL 
   ;
/

-- Ever Cake is a Dessert
-- But not every dessert is a cake.
CREATE TYPE cake_t UNDER dessert_t ( 
   diameter      NUMBER, 
   inscription   VARCHAR2(200) 
   ) 
   ;
/

-- Create Relational Table with Object Type Columns
-- Yes, you can do this! Best of both worlds? 
CREATE TABLE meal ( 
   served_on DATE, 
   appetizer food_t, 
   main_course food_t, 
   dessert dessert_t 
   ) 
   COLUMN appetizer NOT SUBSTITUTABLE AT ALL LEVELS;

-- Populate the Meal Table
-- Call constructor functions directly within INSERT statements to create object type instances and load into the table.
BEGIN 
  INSERT INTO meal VALUES ( 
     SYSDATE, 
     food_t ('Shrimp cocktail', 'PROTEIN', 'Ocean'), 
     food_t ('Eggs benedict', 'PROTEIN', 'Farm'), 
     dessert_t ('Strawberries and cream', 'FRUIT', 'Backyard', 'N', 2001)); 
       
  INSERT INTO meal VALUES ( 
     SYSDATE + 1, 
     food_t ('Shrimp cocktail', 'PROTEIN', 'Ocean'), 
     food_t ('Stir fry tofu', 'PROTEIN', 'Vat'), 
     cake_t ('Apple Pie', 'FRUIT', 'Baker''s Square', 'N', 2001, 8, NULL)); 
      
  INSERT INTO meal VALUES ( 
     SYSDATE + 1, 
     food_t ('Fried Calamari', 'PROTEIN', 'Ocean'), 
     dessert_t ('Butter cookie', 'CARBOHYDRATE', 'Oven', 'N', 2001), 
     cake_t ('French Silk Pie', 'CARBOHYDRATE', 'Baker''s Square', 'Y', 2001, 6,  
        'To My Favorite Frenchman')); 
        
  INSERT INTO meal VALUES ( 
     SYSDATE + 1, 
     food_t ('Fried Calamari', 'PROTEIN', 'Ocean'), 
      cake_t ('French Silk Pie', 'CARBOHYDRATE', 'Baker''s Square', 'Y', 2001, 6,  
        'To My Favorite Frenchman'), 
     dessert_t ('Butter cookie', 'CARBOHYDRATE', 'Oven', 'N', 2001));                 
END;
/

SELECT m.main_course.name 
  FROM meal m 
 WHERE TREAT (main_course AS dessert_t)   
       IS NOT NULL;

-- Failure: main_course is of food_t type
/*
I use TREAT to find all meals whose main course is a dessert. 
But that is not enough. I still cannot directly reference a dessert's attribute 
in the SELECT clause, since meal.main_course is of type food. I must also TREAT 
that (see next step).
*/

SELECT main_course.contains_chocolate  
  FROM meal 
 WHERE TREAT (main_course AS dessert_t)  
       IS NOT NULL ;

-- Success! "Treat" main_course as a dessert 
SELECT TREAT (main_course AS dessert_t).contains_chocolate chocolatey, 
       TREAT (main_course AS dessert_t).year_created 
  FROM meal 
 WHERE TREAT (main_course AS dessert_t) IS NOT NULL;

-- Show Meals with Main Course a Dessert
-- My favorite kind of meal. TREAT returns NULL if the specified instance cannot be downcasted as requested.
SELECT TREAT (main_course AS dessert_t).name 
  FROM meal 
 WHERE TREAT (main_course AS dessert_t) IS NOT NULL;

-- Downcast in DML Statement
-- In this statement, I request that all desserts be changed to type cake. 
-- Remember: every cake is a dessert, but not every dessert is a cake.
UPDATE meal 
   SET dessert = TREAT (dessert AS cake_t);

