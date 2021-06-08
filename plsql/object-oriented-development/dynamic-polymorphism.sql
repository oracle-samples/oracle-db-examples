/*
This script demonstrates dynamic polymorphism with object types. 
So what the heck is dynamic polymorphism? Well, you've probably heard 
of overloading: when 2+ subprograms in a package have the same name. 
Another name for overloading is static polymorphism: "static" means at 
compile time. "polymorphism" means multiple shapes (multiple subprograms, 
same name). Overloading is static polymorphism because the COMPILER 
resolves which of the subprograms to execute (at compile time). 

Dynamic polymorphism means we have 2+ methods with the same name, 
but in different types in the same hierarchy. And the decision on 
which of them to execute happens at RUN-TIME (hence, "dynamic."
*/

-- Root Type: Food!

/*
I like to eat. And we all need to eat. What better root type in my 
hierarchy than "food" - well, I suppose air and water, actually. 
Anyway...three attributes and three member methods.
*/

CREATE TYPE food_t AS OBJECT (  
   NAME         VARCHAR2 (100),  
   food_group   VARCHAR2 (100),  
   grown_in     VARCHAR2 (100),  
 
   MEMBER FUNCTION price RETURN NUMBER,  
   MEMBER FUNCTION to_string RETURN VARCHAR2,  
   MEMBER PROCEDURE show_object  
)  
NOT FINAL; 
/

-- Implement the Methods
-- Nothing fancy. Notice, though, that the to_string method includes 
-- the prefix "FOOD!" so we know which type's method was executed.
CREATE OR REPLACE TYPE BODY food_t  
IS  
   MEMBER FUNCTION price  
      RETURN NUMBER  
   IS  
   BEGIN  
      RETURN (CASE SELF.food_group  
                 WHEN 'PROTEIN'  
                    THEN 3  
                 WHEN 'CARBOHYDRATE'  
                    THEN 2  
                 WHEN 'VEGETABLE'  
                    THEN 1  
              END  
             );  
   END;  
     
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
     
   MEMBER PROCEDURE show_object  
   IS BEGIN  
       DBMS_OUTPUT.PUT_LINE ( '=== Display name of ' || SELF.name || ' ===' );  
       DBMS_OUTPUT.PUT_LINE (SELF.to_string());  
   END;  
END; 
/

-- Every Dessert is a Food
-- But not every food is a dessert. That's what a hierarchy of types (classes) 
-- means. Notice I override both price and to_string methods with ones specific to dessert.
CREATE TYPE dessert_t UNDER food_t (  
   contains_chocolate   CHAR (1),  
   year_created         NUMBER (4),  
 
   OVERRIDING MEMBER FUNCTION price  RETURN NUMBER,  
   OVERRIDING MEMBER FUNCTION to_string RETURN VARCHAR2  
)  
NOT FINAL; 
/

-- Implement the Body

/*
A fancy computation for price: double it, if it contains chocolate, and if 
it was created a loooong time ago, give the price a boost for that too. 
Notice that the to_string method includes the prefix "DESSERT!" so we know 
which type's method was executed. And then it invokes the parent's method as well. 
*/

CREATE OR REPLACE TYPE BODY dessert_t  
IS  
   OVERRIDING MEMBER FUNCTION price  
      RETURN NUMBER  
   IS  
      multiplier   NUMBER := 1;  
   BEGIN  
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
     
   OVERRIDING MEMBER FUNCTION to_string  
      RETURN VARCHAR2  
   IS  
   BEGIN  
      /* ONLY display the dessert information.... */  
        
      RETURN    'DESSERT! With Chocolate? '  
             || SELF.contains_chocolate  
             || '-'  
             || SELF.year_created  
             || chr(10)  
             || (SELF as food_t).to_string;  
   END;  
END; 
/

-- Every Cake is a Dessert
-- But not every dessert is a cake. Oh yeah. We know all about that. 
CREATE TYPE cake_t UNDER dessert_t (  
   diameter      NUMBER,  
   inscription   VARCHAR2 (200),  
 
   OVERRIDING MEMBER FUNCTION to_string RETURN VARCHAR2  
) 
/

-- Implement the Body

/*
Now I only override the to_string function. In other words, no further 
variations for price of a cake, on top of a dessert. My to_string function 
starts with "CAKE!" so we know which type was dynamically selected. And then 
I invoke the dessert's to_string, which in turn invokes the food's to_string.
*/

CREATE OR REPLACE TYPE BODY cake_t  
IS  
     
   OVERRIDING MEMBER FUNCTION to_string  
      RETURN VARCHAR2  
   IS  
   BEGIN  
      /* Call two supertype methods... */  
        
      RETURN  'CAKE! With diameter: '  
           || self.diameter  
           || ' and inscription '  
           || SELF.inscription  
           || chr(10)  
           || (SELF as dessert_t).to_string               
           ;  
   END;  
END; 
/

-- And Now the Magic of Dynamic Polymorphism

/*
I declare a nested table of food types. But since every cake is a dessert 
is a food, I can stuff into this collection an instance of any of these three 
types. That's the substitution feature of object-oriented programming. So in 
they go, cakes and desserts and foods, into the array of foods. But Oracle 
does not forget! When I iterate through the collection and call the show_object 
procedure (which is declared only at the food level), the PL?SQL engine at runtime 
resolves the reference to the to_string method inside show_object according 
to the actual type that was placed in the array.
*/

DECLARE  
   TYPE foodstuffs_nt IS TABLE OF food_t;  
  
   fridge_contents   foodstuffs_nt  
      := foodstuffs_nt (food_t ('Eggs benedict', 'PROTEIN', 'Farm'),  
                        dessert_t ('Strawberries and cream',  
                                   'FRUIT',  
                                   'Backyard',  
                                   'N',  
                                   2001  
                                  ),  
                        cake_t ('Chocolate Supreme',  
                                'CARBOHYDATE',  
                                'Kitchen',  
                                'Y',  
                                2001,  
                                8,  
                                'Happy Birthday, Veva'  
                               )  
                       );  
BEGIN  
   FOR indx IN fridge_contents.FIRST .. fridge_contents.LAST  
   LOOP  
      fridge_contents (indx).show_object();  
   END LOOP;  
END; 
/

DROP TYPE cake_t FORCE;

DROP TYPE dessert_t FORCE;

DROP TYPE food_t FORCE;

