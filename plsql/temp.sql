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

CREATE PACKAGE species_pkg 
IS 
   CURSOR species_cur 
      RETURN endangered_species%ROWTYPE; 
END;
/

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

BEGIN 
   FOR rec IN (  SELECT * 
                   FROM endangered_species 
               ORDER BY common_name) 
   LOOP 
      DBMS_OUTPUT.put_line (rec.common_name); 
   END LOOP; 
END;
/

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

CREATE OR REPLACE PROCEDURE cursor_expression_demo (location_id_in NUMBER) 
IS 
   TYPE refcursor IS REF CURSOR; 
 
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
       WHERE l.location_id = location_id_in; 
 
   department_cur   refcursor; 
   employee_cur     refcursor; 
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

BEGIN
   cursor_expression_demo (1700);
END;
/

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

