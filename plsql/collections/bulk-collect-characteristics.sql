/*
This script demonstrates key characteristics of a collection populated by a 
BULK COLLECT fetch: it is either empty or sequentially filled from index value 1.
*/

DECLARE
   TYPE emps_t IS TABLE OF hr.employees%ROWTYPE;

   l_emps     emps_t;

   l_cursor   SYS_REFCURSOR;
BEGIN
   /* Always filled sequentially from 1 */
   SELECT *
     BULK COLLECT INTO l_emps
     FROM hr.employees;

   DBMS_OUTPUT.put_line ('FIRST=' || l_emps.FIRST);
   DBMS_OUTPUT.put_line ('LAST=' || l_emps.LAST);
   DBMS_OUTPUT.put_line ('COUNT=' || l_emps.COUNT);

   /* Or it is empty */
   SELECT *
     BULK COLLECT INTO l_emps
     FROM hr.employees
    WHERE 1 = 2;

   DBMS_OUTPUT.put_line (
         'FIRST='
      || NVL (TO_CHAR (l_emps.FIRST),
              'LAST is NULL when collection is empty'));
   DBMS_OUTPUT.put_line (
         'LAST='
      || NVL (TO_CHAR (l_emps.LAST), 'LAST is NULL when collection is empty'));
   DBMS_OUTPUT.put_line ('COUNT=' || l_emps.COUNT);

   /* So this loop is "safe" regardless of how many elements in collection... */

   FOR indx IN 1 .. l_emps.COUNT
   LOOP
      DBMS_OUTPUT.put_line (l_emps (indx).last_name);
   END LOOP;

   /* But this one is not */
   BEGIN
      FOR indx IN l_emps.FIRST .. l_emps.LAST
      LOOP
         DBMS_OUTPUT.put_line (l_emps (indx).last_name);
      END LOOP;
   EXCEPTION
      WHEN VALUE_ERROR
      THEN
         DBMS_OUTPUT.put_line ('Low and high in FOR loop must be non-NULL!');
   END;

   /* Fetch with limit */
   OPEN l_cursor FOR SELECT * FROM hr.employees;

   FETCH l_cursor BULK COLLECT INTO l_emps LIMIT 25;

   DBMS_OUTPUT.put_line ('FIRST=' || l_emps.FIRST);
   DBMS_OUTPUT.put_line ('LAST=' || l_emps.LAST);
   DBMS_OUTPUT.put_line ('COUNT=' || l_emps.COUNT);

   CLOSE l_cursor;
END;
/

