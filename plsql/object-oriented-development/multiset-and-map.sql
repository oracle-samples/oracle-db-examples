/*
The MULTISET operators are fantastic, declarative, set-oriented functionality 
for nested tables. But if you have a nested table of object types, then you will 
also need to provide a MAP method for that object type if your MULTISET needs 
to do a comparison. Which is true for pretty much every variation on MULTISET 
except for MULTISET UNION [ALL]. 

For full explanation, see my blog post: 

https://stevenfeuersteinonplsql.blogspot.com/2018/10/why-wont-multiset-work-for-me.html
*/

CREATE TABLE limbs
(
   nm        VARCHAR2 (100),
   avg_len   NUMBER
);

BEGIN
   INSERT INTO limbs VALUES ('arm', 1);

   INSERT INTO limbs VALUES ('leg', 2);

   INSERT INTO limbs VALUES ('tail', 3);

   COMMIT;
END;
/

CREATE OR REPLACE TYPE limb_ot AUTHID DEFINER 
   IS OBJECT 
(
   nm VARCHAR2 (100),
   avg_len NUMBER
)
/

-- Works Just Fine
-- MULTISET UNION = MULTISET UNION ALL, which means no checking for duplicates, 
-- which means no need to compare, so no problem!
DECLARE
   TYPE limbs_t IS TABLE OF limb_ot;

   l_limbs   limbs_t;
BEGIN
     SELECT limb_ot (l.nm, l.avg_len)
       BULK COLLECT INTO l_limbs
       FROM limbs l
   ORDER BY l.nm;

   l_limbs := l_limbs MULTISET UNION l_limbs;
   DBMS_OUTPUT.put_line ('Lots of limbs! ' || l_limbs.COUNT);
END;
/

-- Even Works for %ROWTYPE Elements!
-- Again, no need to make a comparison, so we are good.
DECLARE
   TYPE limbs_t IS TABLE OF limbs%ROWTYPE;

   l_limbs   limbs_t;
BEGIN
     SELECT l.nm, l.avg_len
       BULK COLLECT INTO l_limbs
       FROM limbs l
   ORDER BY l.nm;

   l_limbs := l_limbs MULTISET UNION l_limbs;
   DBMS_OUTPUT.put_line ('Lots of limbs! ' || l_limbs.COUNT);
END;
/

-- EXCEPT Requires Comparison
-- Now we get an error. MULTISET EXCEPT can't do its job without comparing 
-- contents of the object type. The limb_ot object type has no map method (yet!), so it fails.
DECLARE
   TYPE limbs_t IS TABLE OF limb_ot;

   l_limbs   limbs_t;
BEGIN
     SELECT limb_ot (l.nm, l.avg_len)
       BULK COLLECT INTO l_limbs
       FROM limbs l
   ORDER BY l.nm;

   l_limbs := l_limbs MULTISET EXCEPT l_limbs;
   DBMS_OUTPUT.put_line ('Lots of limbs! ' || l_limbs.COUNT);
END;
/

-- UNION DISTINCT - Compares
-- I add the DISTINCT modifier and now MULTISET UNION doesn't work.
DECLARE
   TYPE limbs_t IS TABLE OF limb_ot;
   l_limbs   limbs_t;
BEGIN
     SELECT limb_ot (l.nm, l.avg_len)
       BULK COLLECT INTO l_limbs
       FROM limbs l
   ORDER BY l.nm;

   l_limbs := l_limbs MULTISET UNION DISTINCT l_limbs;
   DBMS_OUTPUT.put_line ('Lots of limbs! ' || l_limbs.COUNT);
END;
/

-- Add a Map Method!
CREATE OR REPLACE TYPE limb_ot AUTHID DEFINER 
   IS OBJECT
(
   nm VARCHAR2 (100),
   avg_len NUMBER,
   MAP MEMBER FUNCTION limb_map
      RETURN NUMBER
)
/

-- It's a silly mapping algorithm - only looks at the length of the name. 
-- When you create your map method, make sure it reflects the logic of your data.
CREATE OR REPLACE TYPE BODY limb_ot
IS
   MAP MEMBER FUNCTION limb_map
      RETURN NUMBER
   IS
   BEGIN
      RETURN LENGTH (self.nm);
   END;
END;
/

-- Now UNION DISTINCT Works
/*
With the map method in place, MULTISET operations that require comparisons 
now work. But wait - only 2 elements in the resulting UNION DISTINCT? But all 
three rows are distinct - what's going on? Hint: see mapping algorithm.
*/

DECLARE
   TYPE limbs_t IS TABLE OF limb_ot;
   l_limbs   limbs_t;
BEGIN
     SELECT limb_ot (l.nm, l.avg_len)
       BULK COLLECT INTO l_limbs
       FROM limbs l
   ORDER BY l.nm;

   l_limbs := l_limbs MULTISET UNION DISTINCT l_limbs;
   DBMS_OUTPUT.put_line ('Lots of limbs! ' || l_limbs.COUNT);
END;
/

-- Now MULTISET EXCEPT works - and nothing is left when you "minus" something from itself.
DECLARE
   TYPE limbs_t IS TABLE OF limb_ot;

   l_limbs   limbs_t;
BEGIN
     SELECT limb_ot (l.nm, l.avg_len)
       BULK COLLECT INTO l_limbs
       FROM limbs l
   ORDER BY l.nm;

   l_limbs := l_limbs MULTISET EXCEPT l_limbs;
   DBMS_OUTPUT.put_line ('Lots of limbs! ' || l_limbs.COUNT);
END;
/

-- But Still Not with %ROWTYPE
-- Sorry, there is no way currently in PL/SQL to either create an analogue of 
-- a mapping method to a record type or compare records generally.
DECLARE
   TYPE limbs_t IS TABLE OF limbs%ROWTYPE;

   l_limbs   limbs_t;
BEGIN
     SELECT l.nm, l.avg_len
       BULK COLLECT INTO l_limbs
       FROM limbs l
   ORDER BY l.nm;

   l_limbs := l_limbs MULTISET EXCEPT l_limbs;
   DBMS_OUTPUT.put_line ('Lots of limbs! ' || l_limbs.COUNT);
END;
/

-- Tweak Mapping Algorithm

/*
Remember that statement that showed only 2 rows were distinct? 
That's not right - well, wait, but it was correct, given the simplistic 
mapping algorithm. The names of two limbs were the same: 3, so they mapped 
to the "same" as for as DISTINCT goes. Let's improve that algorithm!
*/

CREATE OR REPLACE TYPE BODY limb_ot
IS
   MAP MEMBER FUNCTION limb_map
      RETURN NUMBER
   IS
   BEGIN
      RETURN LENGTH (self.nm) + self.avg_len;
   END;
END;
/

-- Mapping Algorithms Matter
-- With the new algorithm, the DISTINCT operation now gets a different value 
-- for each row and so 3 elements are assigned to l_limbs.
DECLARE
   TYPE limbs_t IS TABLE OF limb_ot;

   l_limbs   limbs_t;
BEGIN
     SELECT limb_ot (l.nm, l.avg_len)
       BULK COLLECT INTO l_limbs
       FROM limbs l
   ORDER BY l.nm;

   l_limbs := l_limbs MULTISET UNION DISTINCT l_limbs;
   DBMS_OUTPUT.put_line ('Lots of limbs! ' || l_limbs.COUNT);
END;
/

