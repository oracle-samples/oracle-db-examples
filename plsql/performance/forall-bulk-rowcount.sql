/*
SQL%BULK_ROWCOUNT is a pseudo-collection that contains one element for each 
DML statement executed by FORALL. The element contains the number of rows modified 
by that specific DML statement. SQL%ROWCOUNT returns the total number of rows 
modified by the FORALL, overall.
*/

-- Created Nested Table for Use in FORALL
CREATE OR REPLACE TYPE idlist_t IS TABLE OF INTEGER; 
/

-- Helper Procedure to Create "Log" Table
/*
In this script I will as a side benefit demonstrate that you can use FORALL 
with dynamic SQL. I plan to get the IDs of all rows modified, and store them 
in the empno_temp table. I will remove the table if it already exists, which 
means at the time I compile my demonstration program, empno_temp might not exist 
- hence the need for dynamic SQL.
*/

CREATE OR REPLACE PROCEDURE put_in_table (n_in IN idlist_t)  
IS  
   PRAGMA AUTONOMOUS_TRANSACTION;  
BEGIN  
   BEGIN  
      EXECUTE IMMEDIATE 'drop table empno_temp';  
   EXCEPTION  
      WHEN OTHERS  
      THEN  
         NULL;  
   END;  
  
   EXECUTE IMMEDIATE 'create table empno_temp (empid INTEGER)';  
  
   FORALL indx IN 1 .. n_in.COUNT  
      EXECUTE IMMEDIATE 'insert into empno_temp values (:empno)'  
         USING n_in (indx);  
  
   COMMIT;  
EXCEPTION  
   WHEN OTHERS  
   THEN  
      ROLLBACK;  
      RAISE;  
END; 
/

-- Exercise SQL%BULK_ROWCOUNT
/*
Let's give a 10% raise to anyone whose name starts with an "S" or "E" or 
contains an "A". What, that sounds silly to you? Well, I am sure in your lengthy 
professional career, you've sometimes looked around Cubicleland and asked yourself: 
"Why did HE get the raise and not me?" Now you know. :-) 
*/
DECLARE  
   TYPE namelist_t IS TABLE OF employees.last_name%TYPE;  
  
   ename_filter   namelist_t := namelist_t ('S%', 'E%', '%A%');  
   empnos         idlist_t;  
BEGIN  
   /* If I don't use constructor I have to do all this:  
   ename_filter.extend (3);  
   ename_filter (1) := 'S%';  
   ename_filter (2) := 'E%';  
   ename_filter (3) := '%A%';  
   */  
  
   -- Using SQL%BULK_ROWCOUNT: how many rows modified  
   -- by each statement?  
  
   FORALL indx IN 1 .. ename_filter.COUNT  
         UPDATE employees  
            SET salary = salary * 1.1  
          WHERE UPPER (last_name) LIKE ename_filter (indx)  
      RETURNING employee_id  
           BULK COLLECT INTO empnos;  
  
   DBMS_OUTPUT.put_line (SQL%ROWCOUNT);  
  
   FOR indx IN 1 .. ename_filter.COUNT  
   /*  
      The COUNT method is not implemented on the SQL%BULK_ROWCOUNT  
      pseudo collection. You must use the COUNT of the bind array,  
      since that "drives" the number of statements generated and  
      executed by FORALL.  
   */  
   LOOP  
      DBMS_OUTPUT.put_line (  
            'Number of employees with names like "'  
         || ename_filter (indx)  
         || '" given a raise: '  
         || SQL%BULK_ROWCOUNT (indx));  
   END LOOP;  
  
   DBMS_OUTPUT.put_line (empnos.COUNT || ' rows modifed!');  
   ROLLBACK;  
  
   FOR indx IN 1 .. empnos.COUNT  
   LOOP  
      DBMS_OUTPUT.put_line (empnos (indx));  
   END LOOP;  
  
   put_in_table (empnos);  
END; 
/

