/*
An exploration into the different ways you can define and use cursors 
(pointers to SQL result sets) in PL/SQL, including: implicit cursor, 
explicit cursor, cursor expressions, cursor variables, DBMS_SQL cursor handles. 

More details available at my blog: 

http://stevenfeuersteinonplsql.blogspot.com/2016/05/types-of-cursors-available-in-plsql.html
*/

-- To Demo Cursors, Need Table With Data
CREATE TABLE endangered_species 
( 
   common_name    VARCHAR2 (100), 
   species_name   VARCHAR2 (100) 
);

BEGIN
   /* https://www.worldwildlife.org/species/directory?direction=desc&sort=extinction_status */
   INSERT INTO endangered_species
        VALUES ('Amur Leopard', 'Panthera pardus orientalis');

   INSERT INTO endangered_species
        VALUES ('Hawksbill Turtle', 'Eretmochelys imbricata');

   INSERT INTO endangered_species
        VALUES ('Javan Rhino', 'Rhinoceros sondaicus');

   COMMIT;
END;
/

-- Implicit Cursor (aka, SELECT-INTO)
/*
Perfect for single row lookups. Raises NO_DATA_FOUND if no row found. 
Raises TOO_MANY_ROWS if > 1 row found. You should decide when using 
SELECT-INTO if NO_DATA_FOUND is an actual error (a row SHOULD exist) or simply a data condition.
*/

DECLARE 
   l_common_name   endangered_species.common_name%TYPE; 
BEGIN 
   SELECT common_name 
     INTO l_common_name 
     FROM endangered_species 
    WHERE species_name = 'Rhinoceros sondaicus'; 
EXCEPTION 
   WHEN NO_DATA_FOUND 
   THEN 
      DBMS_OUTPUT.put_line ('Error or data condition?'); 
   WHEN TOO_MANY_ROWS 
   THEN 
      DBMS_OUTPUT.put_line ('Error if primary key/unique index lookup!'); 
END;
/

-- Bulk Implicit Cursor (aka, SELECT BULK COLLECT INTO)
/*
You can add BULK COLLECT to your INTO clause and then return multiple 
rows with a single fetch, into a collection. In fact, you can add "BULK 
COLLECT" to any INTO (SELECT-INTO, FETCH-INTO, EXECUTE IMMEDIATE-INTO) 
clause. I won't show that below.
*/

DECLARE 
   TYPE species_nt IS TABLE OF endangered_species%ROWTYPE; 
 
   l_species   species_nt; 
BEGIN 
     SELECT * 
       BULK COLLECT INTO l_species 
       FROM endangered_species 
   ORDER BY common_name; 
 
   DBMS_OUTPUT.put_line (l_species.COUNT); 
END;
/

-- Explicit Cursor (aka, CURSOR cursor_name IS SELECT....)
/*
You associate a SELECT statement with an explicitly-declared cursor. 
Then you get to control all aspects: open, fetch, close. If that's what 
you want. Generally do not use explicit cursors for single row lookups; 
implicits are simpler and faster. 
*/

DECLARE 
   CURSOR species_cur 
   IS 
        SELECT * 
          FROM endangered_species 
      ORDER BY common_name; 
 
   l_species   species_cur%ROWTYPE; 
BEGIN 
   OPEN species_cur; 
 
   FETCH species_cur INTO l_species; 
 
   CLOSE species_cur; 
END;
/

-- Parameterize Explicit Cursors
-- You can define a cursor once, and use it in multiple places. 
DECLARE 
   CURSOR species_cur (filter_in IN VARCHAR2) 
   IS 
        SELECT * 
          FROM endangered_species 
         WHERE species_name LIKE filter_in 
      ORDER BY common_name; 
 
   l_species   species_cur%ROWTYPE; 
BEGIN 
   OPEN species_cur ('%u%'); 
   FETCH species_cur INTO l_species; 
   CLOSE species_cur; 
 
   /* Use same cursor a second time, avoiding copy-paste of SQL */ 
   OPEN species_cur ('%e%'); 
   FETCH species_cur INTO l_species; 
   CLOSE species_cur; 
 
   /* I can even use it in a cursor FOR loop */ 
   FOR rec IN species_cur ('%u%') 
   LOOP 
      DBMS_OUTPUT.PUT_LINE (rec.common_name); 
   END LOOP; 
END;
/

-- Explicit Cursor in Package Specification, SQL Hidden
/*
One really nice feature of an explicit cursor is to declare the 
cursor in the specification, but not show the SQL. Then you define 
the cursor (including the SELECT) in the package body - as shown in 
next step. This way, you hide the details of the query and "force" 
the user of the cursor to simply rely on its documented specification.
*/

CREATE PACKAGE species_pkg 
IS 
   CURSOR species_cur 
      RETURN endangered_species%ROWTYPE; 
END;
/

-- Hide SELECT in Package Body
CREATE PACKAGE BODY species_pkg 
IS 
   CURSOR species_cur 
      RETURN endangered_species%ROWTYPE 
   IS 
        SELECT * 
          FROM endangered_species 
      ORDER BY common_name; 
END;
/

-- Cursor FOR Loop with Embedded SELECT
/*
The cursor FOR Loop is one of my favorite PL/SQL features. 
No need to open, fetch, close. Just tell the PL/SQL engine you want 
to work with each row returned by the query. Plus, with your optimization 
level set to 2 (the default) or higher, this code is automatically 
optimized to return 100 rows with each fetch (similar to BULK COLLECT).
*/

BEGIN 
   FOR rec IN (  SELECT * 
                   FROM endangered_species 
               ORDER BY common_name) 
   LOOP 
      DBMS_OUTPUT.put_line (rec.common_name); 
   END LOOP; 
END;
/

-- Cursor FOR Loop with Explicit Cursor
/*
As mentioned above, you can declare the cursor once, then use it 
multiple times. Here, in two different cursor FOR loops.
*/

DECLARE 
   CURSOR species_cur 
   IS 
        SELECT * 
          FROM endangered_species 
      ORDER BY common_name; 
 
   PROCEDURE start_conservation_effort 
   IS 
   BEGIN 
      DBMS_OUTPUT.put_line ('Remove human presence'); 
   END; 
BEGIN 
   FOR rec IN species_cur 
   LOOP 
      DBMS_OUTPUT.put_line (rec.common_name); 
   END LOOP; 
 
   FOR rec IN species_cur 
   LOOP 
      start_conservation_effort; 
   END LOOP; 
END;
/

-- Cursor Variables Based on Strong and Weak Ref Cursor Types
/*
A cursor variable is, well, just that: a variable pointing back to 
a cursor/result set. Some really nice aspects of cursor variables, 
demonstrated in this package: you can associate a query with a cursor 
variable at runtime (useful with both static and dynamic SQL); 
you can pass the cursor variable as a parameter or function RETURN 
value (specifically: you can pass a cursor variable back to a host l
anguage like Java for consumption). 
*/

CREATE OR REPLACE PACKAGE refcursor_pkg 
IS 
   /* Use this "strong" REF CURSOR to declare cursor variables whose 
      queries return data from the endangered_species table. */ 
 
   TYPE endangered_species_t IS REF CURSOR 
      RETURN endangered_species%ROWTYPE; 
 
   /* Use a "weak" REF CURSOR to declare cursor variables whose 
      queries return any number of columns. 
 
      Or use the pre-defined SYS_REFCURSOR, see example below. 
   */ 
 
   TYPE weak_t IS REF CURSOR; 
 
   FUNCTION filtered_species_cv (filter_in IN VARCHAR2) 
      RETURN endangered_species_t; 
 
   /* Return data from whatever query is passed as an argument. */ 
   FUNCTION data_from_any_query_cv (query_in IN VARCHAR2) 
      RETURN weak_t; 
 
   /* Return data from whatever query is passed as an argument. 
      But this time, use the predefined weak type. */ 
   FUNCTION data_from_any_query_cv2 (query_in IN VARCHAR2) 
      RETURN SYS_REFCURSOR; 
END refcursor_pkg;
/

CREATE OR REPLACE PACKAGE BODY refcursor_pkg 
IS 
   FUNCTION filtered_species_cv (filter_in IN VARCHAR2) 
      RETURN endangered_species_t 
   IS 
      l_cursor_variable   endangered_species_t; 
   BEGIN 
      IF filter_in IS NULL 
      THEN 
         OPEN l_cursor_variable FOR SELECT * FROM endangered_species; 
      ELSE 
         OPEN l_cursor_variable FOR 
            SELECT * 
              FROM endangered_species 
             WHERE common_name LIKE filter_in; 
      END IF; 
 
      RETURN l_cursor_variable; 
   END filtered_species_cv; 
 
   FUNCTION data_from_any_query_cv (query_in IN VARCHAR2) 
      RETURN weak_t 
   IS 
      l_cursor_variable   weak_t; 
   BEGIN 
      OPEN l_cursor_variable FOR query_in; 
 
      RETURN l_cursor_variable; 
   END data_from_any_query_cv; 
 
   FUNCTION data_from_any_query_cv2 (query_in IN VARCHAR2) 
      RETURN SYS_REFCURSOR 
   IS 
      l_cursor_variable   SYS_REFCURSOR; 
   BEGIN 
      OPEN l_cursor_variable FOR query_in; 
 
      RETURN l_cursor_variable; 
   END data_from_any_query_cv2; 
END refcursor_pkg;
/

-- Using Standard Cursor Operations with Cursor Variables
/*
Once you've got a cursor variable, you can use all the familiar 
features of explicit cursors with them: fetch, close, check cursor attribute values.
*/

DECLARE 
   l_objects   refcursor_pkg.endangered_species_t; 
   l_object    endangered_species%ROWTYPE; 
BEGIN 
   l_objects := refcursor_pkg.filtered_species_cv ('%u%'); 
 
   LOOP 
      FETCH l_objects INTO l_object; 
 
      EXIT WHEN l_objects%NOTFOUND; 
 
      DBMS_OUTPUT.put_line (l_object.common_name); 
   END LOOP; 
 
   CLOSE l_objects; 
END;
/

-- Cursor Variable for Dynamic Query
/*
Just pass whatever query you want, OPEN FOR that query, and 
pass back the cursor variable. The tricky part is figuring out 
how many columns and their types in that dynamic query. DBMS_SQL.DESCRIBE_COLUMNS, 
in conjunction with DBMS_SQL.to_cursor_number, can help there.
*/

DECLARE 
   l_objects   SYS_REFCURSOR; 
   l_object    endangered_species%ROWTYPE; 
BEGIN 
   l_objects := 
      refcursor_pkg.data_from_any_query_cv2 ( 
         'SELECT * FROM endangered_species WHERE common_name LIKE ''%u%'''); 
 
   LOOP 
      FETCH l_objects INTO l_object; 
 
      EXIT WHEN l_objects%NOTFOUND; 
      DBMS_OUTPUT.put_line (l_object.common_name); 
   END LOOP; 
 
   CLOSE l_objects; 
END;
/

-- Cursor Expressions
/*
Taking a break from endangered species and a shift to HR to show you 
how you can use the CURSOR expression to convert a result set into a 
cursor variable. Also useful with pipelined table functions.
*/

DECLARE 
   /* Notes on CURSOR expression:  
  
      1. The query returns only 2 columns, but the second column is  
         a cursor that lets us traverse a set of related information.  
  
      2. Queries in CURSOR expression that find no rows do NOT raise  
         NO_DATA_FOUND.  
   */  
   CURSOR all_in_one_cur  
   IS  
      SELECT l.city,  
             CURSOR (SELECT d.department_name,  
                            CURSOR (SELECT e.last_name  
                                      FROM hr.employees e  
                                     WHERE e.department_id = d.department_id)  
                               AS ename  
                       FROM hr.departments d  
                      WHERE l.location_id = d.location_id)  
                AS dname  
        FROM hr.locations l 
       WHERE l.location_id = 1700;  
  
   department_cur   sys_refcursor;  
   employee_cur     sys_refcursor;  
   v_city           hr.locations.city%TYPE;  
   v_dname          hr.departments.department_name%TYPE;  
   v_ename          hr.employees.last_name%TYPE;  
BEGIN  
   OPEN all_in_one_cur;  
  
   LOOP  
      FETCH all_in_one_cur INTO v_city, department_cur;  
  
      EXIT WHEN all_in_one_cur%NOTFOUND;  
  
      -- Now I can loop through deartments and I do NOT need to  
      -- explicitly open that cursor. Oracle did it for me.  
      LOOP  
         FETCH department_cur INTO v_dname, employee_cur;  
  
         EXIT WHEN department_cur%NOTFOUND;  
  
         -- Now I can loop through employee for that department.  
         -- Again, I do need to open the cursor explicitly.  
         LOOP  
            FETCH employee_cur INTO v_ename;  
  
            EXIT WHEN employee_cur%NOTFOUND;  
            DBMS_OUTPUT.put_line (v_city || ' ' || v_dname || ' ' || v_ename);  
         END LOOP;  
  
         CLOSE employee_cur;  
      END LOOP;  
  
      CLOSE department_cur;  
   END LOOP;  
  
   CLOSE all_in_one_cur;  
END; 
/

-- DBMS_SQL Cursor Handle
/*
Most dynamic SQL requirements can be met with EXECUTE IMMEDIATE 
(native dynamic SQL). Some of the more complicated scenarios, however, 
like method 4 dynamic SQL (variable number of elements in SELECT list 
and/or variable number of bind variables) are best implemented by DBMS_SQL. 
You allocate a cursor handle and then all subsequent operations reference that cursor handle.
*/

CREATE OR REPLACE PROCEDURE show_common_names (table_in IN VARCHAR2)  
IS  
   l_cursor     PLS_INTEGER := DBMS_SQL.open_cursor ();  
   l_feedback   PLS_INTEGER;  
   l_name       endangered_species.common_name%TYPE;  
BEGIN  
   DBMS_SQL.parse (l_cursor,  
                   'select common_name from ' || table_in,  
                   DBMS_SQL.native);  
  
   DBMS_SQL.define_column (l_cursor, 1, 'a', 100);  
  
   l_feedback := DBMS_SQL.execute (l_cursor);  
  
   DBMS_OUTPUT.put_line ('Result=' || l_feedback);  
  
   LOOP  
      EXIT WHEN DBMS_SQL.fetch_rows (l_cursor) = 0;  
      DBMS_SQL.COLUMN_VALUE (l_cursor, 1, l_name);  
      DBMS_OUTPUT.put_line (l_name);  
   END LOOP;  
  
   DBMS_SQL.close_cursor (l_cursor);  
END;
/

BEGIN
   show_common_names ('ENDANGERED_SPECIES');
END;
/

