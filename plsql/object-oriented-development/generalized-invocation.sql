/*
PL/SQL supports object-oriented development via object types (our version of classes). 
In Oracle Database 11g, you can now reference the method of a (any) supertype in the 
type hierarchy via a generalized invocation.
*/

-- Create the Object Type Hierarchy
-- Root type is food, all desserts are a type of food, all cakes are a type of dessert.
-- But not all desserts are cakes. Not all food is dessert. Too bad! :-)
CREATE TYPE food_t AS OBJECT  
       (name VARCHAR2 (100)  
      , food_group VARCHAR2 (100)  
      , grown_in VARCHAR2 (100)  
      , MEMBER FUNCTION to_string  
           RETURN VARCHAR2)  
          NOT FINAL; 
/

CREATE OR REPLACE TYPE BODY food_t 
IS 
   MEMBER FUNCTION to_string 
      RETURN VARCHAR2 
   IS 
   BEGIN 
      RETURN    'FOOD! ' 
             || self.name 
             || '-' 
             || self.food_group 
             || '-' 
             || self.grown_in; 
   END; 
END; 
/

-- Override to_string Method
-- Tweak the string representation of a dessert to specialize it, compared to general dessert strings.
CREATE TYPE dessert_t  
          UNDER food_t  
       (contains_chocolate CHAR (1)  
      , OVERRIDING MEMBER FUNCTION to_string  
           RETURN VARCHAR2)  
          NOT FINAL; 
/

CREATE OR REPLACE TYPE BODY dessert_t 
IS 
   OVERRIDING MEMBER FUNCTION to_string 
      RETURN VARCHAR2 
   IS 
   BEGIN 
      /* Display the dessert information + food info. */ 
 
      RETURN 'DESSERT! Chocolate='  
          || contains_chocolate  
          || ' '  
          || (SELF as food_t).to_string   ; 
   END; 
END; 
/

-- Second Override of to_string Method
-- Further specialize the way a cake is represented as a string
CREATE TYPE cake_t  
          UNDER dessert_t  
       (diameter NUMBER  
      , OVERRIDING MEMBER FUNCTION to_string  
           RETURN VARCHAR2); 
/

CREATE OR REPLACE TYPE BODY cake_t 
IS 
   OVERRIDING MEMBER FUNCTION to_string 
      RETURN VARCHAR2 
   IS 
   BEGIN 
      /* Call two supertype methods... */ 
 
      RETURN    'CAKE! Diameter=' 
             || self.diameter 
             || ' ' 
             || (SELF as dessert_t).to_string; 
   END; 
END; 
/

-- Dynamic Polymorphism At Work
-- At runtime, the engine determines which method in the hierarchy should be invoked. 
-- That's pretty cool. But what if you want to override that and pick a specific supertype method?
DECLARE  
   TYPE foodstuffs_nt IS TABLE OF food_t;  
  
   fridge_contents   foodstuffs_nt  
      := foodstuffs_nt (food_t ('Eggs benedict', 'PROTEIN', 'Farm')  
                      , dessert_t ('Strawberries and cream'  
                                 , 'FRUIT'  
                                 , 'Backyard'  
                                 , 'N')  
                      , cake_t ('Chocolate Supreme'  
                              , 'CARBOHYDATE'  
                              , 'Kitchen'  
                              , 'Y'  
                              , 8));  
BEGIN  
   FOR indx IN fridge_contents.FIRST .. fridge_contents.LAST  
   LOOP  
      DBMS_OUTPUT.put_line (fridge_contents (indx).to_string);  
   END LOOP;  
END; 
/

-- Change Cake's to_string to "Skip" Over Dessert
-- I don't want to invoke cake's to_string. I don't even want to invoke dessert's to_string. 
-- I want to go all the way up to food: (SELF as food_t).to_string
CREATE OR REPLACE TYPE BODY cake_t  
IS  
   OVERRIDING MEMBER FUNCTION to_string  
      RETURN VARCHAR2  
   IS  
   BEGIN  
      /* Call two supertype methods... */  
  
      RETURN    'CAKE! Diameter='  
             || self.diameter  
             || ' '  
             || (SELF as food_t).to_string;  
   END;  
END; 
/

-- Cake Display Now Different!
DECLARE  
   TYPE foodstuffs_nt IS TABLE OF food_t;  
  
   fridge_contents   foodstuffs_nt  
      := foodstuffs_nt (food_t ('Eggs benedict', 'PROTEIN', 'Farm')  
                      , dessert_t ('Strawberries and cream'  
                                 , 'FRUIT'  
                                 , 'Backyard'  
                                 , 'N')  
                      , cake_t ('Chocolate Supreme'  
                              , 'CARBOHYDATE'  
                              , 'Kitchen'  
                              , 'Y'  
                              , 8));  
BEGIN  
   FOR indx IN fridge_contents.FIRST .. fridge_contents.LAST  
   LOOP  
      DBMS_OUTPUT.put_line (fridge_contents (indx).to_string);  
   END LOOP;  
END; 
/

