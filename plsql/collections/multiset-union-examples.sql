/*
Use MULTISET UNION to perform set-level union operations on nested tables. 
Remember: with MULTISET, ALL is the default, not DISTINCT (the opposite 
holds true with SQL UNION).
*/

CREATE OR REPLACE TYPE strings_nt IS TABLE OF VARCHAR2 (1000) 
/

CREATE OR REPLACE PACKAGE authors_pkg 
IS 
   steven_authors   strings_nt; 
   veva_authors     strings_nt; 
   eli_authors      strings_nt; 
 
   PROCEDURE show_authors (title_in IN VARCHAR2, authors_in IN strings_nt); 
 
   PROCEDURE init_authors; 
END;
/

CREATE OR REPLACE PACKAGE BODY authors_pkg 
IS 
   PROCEDURE show_authors (title_in IN VARCHAR2, authors_in IN strings_nt) 
   IS 
   BEGIN 
      DBMS_OUTPUT.put_line (title_in); 
 
      FOR indx IN 1 .. authors_in.COUNT 
      LOOP 
         DBMS_OUTPUT.put_line (indx || ' = ' || authors_in (indx)); 
      END LOOP; 
   END show_authors; 
 
   PROCEDURE init_authors 
   IS 
   BEGIN 
      steven_authors := 
         strings_nt ('ROBIN HOBB' 
                   , 'ROBERT HARRIS' 
                   , 'DAVID BRIN' 
                   , 'SHERI S. TEPPER' 
                   , 'CHRISTOPHER ALEXANDER' 
                   , 'PIERS ANTHONY'); 
      veva_authors := 
         strings_nt ('ROBIN HOBB', 'SHERI S. TEPPER', 'ANNE MCCAFFREY'); 
 
      eli_authors := 
         strings_nt ('PIERS ANTHONY', 'SHERI S. TEPPER', 'DAVID BRIN'); 
   END; 
END;
/

DECLARE 
   our_authors   strings_nt; 
BEGIN 
   authors_pkg.init_authors; 
   our_authors := 
      authors_pkg.steven_authors MULTISET UNION authors_pkg.veva_authors; 
 
   authors_pkg.show_authors ('Steven and Veva', our_authors); 
 
   /* Use MULTISET UNION inside SQL */ 
   DBMS_OUTPUT.put_line ('Union inside SQL'); 
 
   FOR rec IN (  SELECT COLUMN_VALUE 
                   FROM TABLE ( 
                           authors_pkg.veva_authors 
                              MULTISET UNION authors_pkg.steven_authors) 
               ORDER BY COLUMN_VALUE) 
   LOOP 
      DBMS_OUTPUT.put_line (rec.COLUMN_VALUE); 
   END LOOP; 
 
   our_authors := 
      authors_pkg.steven_authors 
         MULTISET UNION DISTINCT authors_pkg.veva_authors; 
 
   authors_pkg.show_authors ('Steven then Veva with DISTINCT', our_authors); 
END; 
/

