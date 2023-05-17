/*
 Sure, we say FORALL is fast, but how fast, really? And how does it compare 
 to "pure" SQL (which of course you should use whenever possible!)?
 */

CREATE TABLE parts (partnum NUMBER, partname VARCHAR2 (15));

CREATE TABLE parts2 (partnum NUMBER, partname VARCHAR2 (15));

CREATE OR REPLACE TYPE parts_ot IS OBJECT
   (partnum NUMBER, partname VARCHAR2 (15))
/

CREATE OR REPLACE TYPE partstab IS TABLE OF parts_ot;
/

CREATE OR REPLACE PROCEDURE compare_inserting (num IN INTEGER) 
IS 
   TYPE numtab IS TABLE OF parts.partnum%TYPE; 
 
   TYPE nametab IS TABLE OF parts.partname%TYPE; 
    
   TYPE parts_t is table of parts%ROWTYPE index by pls_integer; 
   parts_tab parts_t; 
 
   pnums      numtab := numtab (); 
   pnames     nametab := nametab (); 
   parts_nt   partstab := partstab (); 
 
   l_start INTEGER;  
  
   PROCEDURE start_timer  
   IS  
   BEGIN  
      l_start := DBMS_UTILITY.GET_CPU_TIME;  
   END start_timer;  
  
   PROCEDURE show_elapsed_time ( message_in IN VARCHAR2 )  
   IS  
   BEGIN  
      DBMS_OUTPUT.put_line ( 
            CASE 
               WHEN message_in IS NULL THEN 'Completed in:' 
               ELSE '"' || message_in || '" completed in: ' 
            END 
         || (DBMS_UTILITY.GET_CPU_TIME - l_start) 
         || ' cs'); 
 
      /* Reset timer */ 
      start_timer; 
   END show_elapsed_time;  
BEGIN 
   pnums.EXTEND (num); 
   pnames.EXTEND (num); 
   parts_nt.EXTEND (num); 
 
   FOR indx IN 1 .. num 
   LOOP 
      pnums (indx) := indx; 
      pnames (indx) := 'Part ' || TO_CHAR (indx); 
      parts_nt (indx) := parts_ot (NULL, NULL); 
      parts_nt (indx).partnum := indx; 
      parts_nt (indx).partname := pnames (indx); 
   END LOOP; 
 
   start_timer; 
 
   FOR indx IN 1 .. num 
   LOOP 
      INSERT INTO parts 
          VALUES (pnums (indx), pnames (indx) ); 
   END LOOP; 
 
   show_elapsed_time ('FOR loop (row by row)' || num); 
 
   ROLLBACK; 
 
   start_timer; 
 
   FORALL indx IN 1 .. num 
      INSERT INTO parts 
          VALUES (pnums (indx), pnames (indx) 
                 ); 
 
   show_elapsed_time ('FORALL (bulk)' || num); 
 
   ROLLBACK; 
 
   start_timer; 
 
   INSERT INTO parts 
      SELECT * 
        FROM TABLE (parts_nt); 
 
   show_elapsed_time ('Insert Select from nested table ' || num); 
 
   ROLLBACK; 
 
   start_timer; 
 
   INSERT /*+ APPEND */ 
         INTO parts 
      SELECT * 
        FROM TABLE (parts_nt); 
 
   show_elapsed_time ('Insert Select WITH DIRECT PATH ' || num); 
 
   ROLLBACK; 
    
   EXECUTE IMMEDIATE 'TRUNCATE TABLE parts'; 
 
   /* Load up the table. */ 
   FOR indx IN 1 .. num 
   LOOP 
      INSERT INTO parts 
          VALUES (indx, 'Part ' || TO_CHAR (indx) 
                 ); 
   END LOOP; 
 
   COMMIT; 
 
   start_timer; 
 
   INSERT INTO parts2 
      SELECT * 
        FROM parts; 
 
   show_elapsed_time ('Insert Select 100% SQL'); 
 
   EXECUTE IMMEDIATE 'TRUNCATE TABLE parts2'; 
 
   start_timer; 
 
   SELECT * 
     BULK COLLECT 
     INTO parts_tab 
     FROM parts; 
 
   FORALL indx IN parts_tab.FIRST .. parts_tab.LAST 
      INSERT INTO parts2 
          VALUES parts_tab (indx); 
 
   show_elapsed_time ('BULK COLLECT - FORALL'); 

   ROLLBACK;
END;
/

BEGIN
   compare_inserting (100000);
END;
/

-- With Associative Arrays
-- A visitor wondered if nested tables were faster than associative arrays. Let's find out!
DECLARE
PROCEDURE compare_inserting (num IN INTEGER) 
IS 
   TYPE numtab IS TABLE OF parts.partnum%TYPE index by pls_integer; 
 
   TYPE nametab IS TABLE OF parts.partname%TYPE index by pls_integer; 
    
   TYPE parts_t is table of parts%ROWTYPE index by pls_integer; 
   parts_tab parts_t; 
 
   pnums      numtab; 
   pnames     nametab ; 
   parts_nt   partstab ; 
 
   l_start INTEGER;  
  
   PROCEDURE start_timer  
   IS  
   BEGIN  
      l_start := DBMS_UTILITY.GET_CPU_TIME;  
   END start_timer;  
  
   PROCEDURE show_elapsed_time ( message_in IN VARCHAR2 )  
   IS  
   BEGIN  
      DBMS_OUTPUT.put_line ( 
            CASE 
               WHEN message_in IS NULL THEN 'Completed in:' 
               ELSE '"' || message_in || '" completed in: ' 
            END 
         || (DBMS_UTILITY.GET_CPU_TIME - l_start) 
         || ' cs'); 
 
      /* Reset timer */ 
      start_timer; 
   END show_elapsed_time;   
BEGIN 
   FOR indx IN 1 .. num 
   LOOP 
      pnums (indx) := indx; 
      pnames (indx) := 'Part ' || TO_CHAR (indx); 
   END LOOP; 
 
   start_timer; 
 
   FORALL indx IN 1 .. num 
      INSERT INTO parts 
          VALUES (pnums (indx), pnames (indx) 
                 ); 

   show_elapsed_time ('FORALL with associative arrays' || num); 
   
   ROLLBACK;
END;
BEGIN
   compare_inserting (100000);
END;
/



