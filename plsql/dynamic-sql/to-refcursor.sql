/*
This function takes an OPENed, PARSEd, and EXECUTEd cursor and transforms/migrates 
it into a PL/SQL manageable REF CURSOR (a weakly-typed cursor) that can be consumed 
by PL/SQL native dynamic SQLswitched to use native dynamic SQL. This subprogram is 
only used with SELECT cursors. Primary use case: you have a dynamic number of bind 
variables (leading to use of DBMS_SQL) but static list of expressions in SELECT list 
(handled more easily with cursor variables).

Doc link: http://docs.oracle.com/cd/B28359_01/appdev.111/b28419/d_sql.htm#CHDFDCDE
*/

DECLARE  
   TYPE strings_t IS TABLE OF VARCHAR2 (200);  
  
   l_cv             sys_refcursor;  
   l_placeholders   strings_t     := strings_t ('dept_id');  
   l_values         strings_t     := strings_t ('50');  
   l_names          strings_t;  
  
   FUNCTION employee_names (  
      where_in            IN   VARCHAR2  
    , bind_variables_in   IN   strings_t  
    , placeholders_in     IN   strings_t  
   )  
      RETURN sys_refcursor  
   IS  
      l_dyn_cursor   NUMBER;  
      l_cv           sys_refcursor;  
      l_dummy        PLS_INTEGER;  
   BEGIN  
      /* Parse the retrieval of last names after appending the WHERE clause.  
  
      NOTE: if you ever write code like this yourself, you MUST take steps  
      to minimize the risk of SQL injecction.   
      */  
      l_dyn_cursor := DBMS_SQL.open_cursor;  
      DBMS_SQL.parse (l_dyn_cursor  
                    , 'SELECT last_name FROM hr.employees WHERE ' || where_in  
                    , DBMS_SQL.native  
                     );  
  
      /*  
         Bind each of the variables to the named placeholders;  
         You cannot use EXECUTE IMMEDIATE for this step if you have  
         a variable number of placeholders!  
      */  
      FOR indx IN 1 .. placeholders_in.COUNT  
      LOOP  
         DBMS_SQL.bind_variable (l_dyn_cursor  
                               , placeholders_in (indx)  
                               , bind_variables_in (indx)  
                                );  
      END LOOP;  
  
      /*  
      Execute the query now that all variables are bound.  
      */  
      l_dummy := DBMS_SQL.EXECUTE (l_dyn_cursor);  
      /*  
      Now it's time to convert to a cursor variable so that the front end  
      program or another PL/SQL program can easily fetch the values.  
      */  
      l_cv := DBMS_SQL.to_refcursor (l_dyn_cursor);  
      /*  
      Do not close with DBMS_SQL; you can ONLY manipulate the cursor  
      through the cursor variable at this point.  
      DBMS_SQL.close_cursor (l_dyn_cursor);  
      */  
      RETURN l_cv;  
   END employee_names;  
BEGIN  
   l_cv :=  
        employee_names ('DEPARTMENT_ID = :dept_id', l_values, l_placeholders);  
  
   FETCH l_cv  
   BULK COLLECT INTO l_names;  
  
   FOR indx IN 1 .. l_names.COUNT  
   LOOP  
      DBMS_OUTPUT.put_line (l_names(indx));  
   END LOOP;  
  
   CLOSE l_cv;  
END; 
/

