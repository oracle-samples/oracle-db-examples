/*
While PL/SQL is mostly used to provide secure, efficient access to the relational 
tables (SQL), you can also - to some extent - follow an object-oriented approach 
as well. PL/SQL doesn't offer classes, but instead OBJECT TYPEs. You can then declare 
instances of the object type (just like an object is an instance of a class). 
You can declare static and member methods, take advantage of inheritance, and 
many other expected O-O features. One thing you cannot do, though, is declare 
private attributes and methods. It's all public in object types. 
*/

-- Base or Root Object Type

/*
I like to eat. So let's build a class hierarchy of food. Each instance of 
food has a name, a good group, and the place it is grown. I also include a 
function to return the price of the food - but I do not implement that function. 
Instead, it and the type are NOT INSTANTIABLE. This means you cannot declare an 
instance of food_t. Instead you must define child object types that implement 
the price function, and then you can declare and manipulate variables based on those child types.
*/

CREATE TYPE food_t AS OBJECT (  
   NAME         VARCHAR2 (100)  
 , food_group   VARCHAR2 (100)  
 , grown_in     VARCHAR2 (100)  
 ,  
   -- Generic foods cannot have a price, but we can  
   -- insist that all subtypes DO implement a price  
   -- function.  
   NOT INSTANTIABLE MEMBER FUNCTION price  
      RETURN NUMBER  
)  
NOT FINAL NOT INSTANTIABLE; 
/

-- Every Dessert is a Food

/*
But not every food is a dessert. That's what the hierarchy says. 
Note that this type is instantiable. Which means I must include an object 
type body that implements price.
*/

CREATE TYPE dessert_t UNDER food_t (  
   contains_chocolate   CHAR (1)  
 , year_created         NUMBER (4)  
 , OVERRIDING MEMBER FUNCTION price  
      RETURN NUMBER  
)  
NOT FINAL; 
/

-- An Object Type Body
/*
I override the base price function with an actual implementation. 
As you can see and would expect, the price goes up if the dessert contains chocolate.
*/
CREATE OR REPLACE TYPE BODY dessert_t  
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

-- Every Cake is a Dessert
-- But not every dessert is a cake. And I override dessert's price function with one specially for cake.
CREATE TYPE cake_t UNDER dessert_t (  
   diameter      NUMBER  
 , inscription   VARCHAR2 (200)  
 ,  
   -- Inscription and diameter determine the price  
   OVERRIDING MEMBER FUNCTION price  
      RETURN NUMBER  
) 
/

-- Cake-Specific Price Function
-- Cakes often have messages on their surface - an inscription - and you pay by the letter. 
CREATE OR REPLACE TYPE BODY cake_t  
IS  
   OVERRIDING MEMBER FUNCTION price  
      RETURN NUMBER  
   IS  
   BEGIN  
      DBMS_OUTPUT.put_line ('Cake price!');  
      RETURN  (  5.00                                             -- base price  
              + 0.25 * (LENGTH (SELF.inscription))          -- $.25 per letter  
              + 0.50 * diameter  
             );  
   END;  
END; 
/

-- Can I Declare a Food Variable?
-- No! The type is NOT INSTANTIABLE, so this attempt fails.
DECLARE  
   my_favorite_vegetable   food_t  
                           := food_t ('Brussel Sprouts', 'VEGETABLE', 'farm');  
BEGIN  
   DBMS_OUTPUT.put_line (my_favorite_vegetable.price);  
END; 
/

DECLARE 
   last_resort_dessert   dessert_t 
                         := dessert_t ('Jello', 'PROTEIN', 'bowl', 'N', 1887); 
   heavenly_cake         cake_t 
      := cake_t ('Marzepan Delight' 
               , 'CARBOHYDRATE' 
               , 'bakery' 
               , 'N' 
               , 1634 
               , 8 
               , 'Happy Birthday!' 
                ); 
BEGIN 
   DBMS_OUTPUT.put_line (last_resort_dessert.price); 
   DBMS_OUTPUT.put_line (heavenly_cake.price); 
END; 
/

DECLARE 
   TYPE foodstuffs_nt IS TABLE OF food_t; 
 
   fridge_contents   foodstuffs_nt 
      := foodstuffs_nt (dessert_t ('Strawberries and cream' 
                                 , 'FRUIT' 
                                 , 'Backyard' 
                                 , 'N' 
                                 , 2001 
                                  ) 
                      , dessert_t ('Strawberries and cream' 
                                 , 'FRUIT' 
                                 , 'Backyard' 
                                 , 'N' 
                                 , 2001 
                                  ) 
                      , cake_t ('Chocolate Supreme' 
                              , 'CARBOHYDATE' 
                              , 'Kitchen' 
                              , 'Y' 
                              , 2001 
                              , 8 
                              , 'Happy Birthday, Veva' 
                               ) 
                       ); 
BEGIN 
   FOR indx IN fridge_contents.FIRST .. fridge_contents.LAST 
   LOOP 
      DBMS_OUTPUT.put_line (   'Price of ' 
                            || fridge_contents (indx).NAME 
                            || ' = ' 
                            || fridge_contents (indx).price 
                           ); 
   END LOOP; 
END; 
/

-- Store Object Type Instances in Tables
-- You can create relational tables with columns whose types are object types. And substitutability works here too!
CREATE TABLE food_tab (food food_t) 
/

-- Cakes and Desserts are Foods
-- So I can insert them into the table.
DECLARE  
   s_and_c    dessert_t  
                 := dessert_t ('Strawberries and cream',  
                               'FRUIT',  
                               'Backyard',  
                               'N',  
                               2001);  
   choc_sup   cake_t  
                 := cake_t ('Chocolate Supreme',  
                            'CARBOHYDATE',  
                            'Kitchen',  
                            'Y',  
                            2001,  
                            8,  
                            'Happy Birthday, Veva');  
BEGIN  
   INSERT INTO food_tab  
        VALUES (s_and_c);  
  
   INSERT INTO food_tab  
        VALUES (choc_sup);  
END; 
/

SELECT COUNT (*) FROM food_tab 
/

