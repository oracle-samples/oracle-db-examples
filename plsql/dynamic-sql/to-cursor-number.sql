/*
This function takes an OPENed strongly or weakly-typed ref cursor and transforms 
it into a DBMS_SQL cursor number. Primary use case: dynamic SQL scenario in which 
you have a fixed number of bind variables (handled neatly with cursor variables) 
and a variable number of expressions in the SELECT list (handled best with DBMS_SQL).

Doc: http://docs.oracle.com/cd/B28359_01/appdev.111/b28419/d_sql.htm#CHDJDGDG

*/

CREATE OR REPLACE PROCEDURE show_data (  
   column_list_in          VARCHAR2  
 , department_id_in   IN   hr.employees.department_id%TYPE  
)  
IS  
   TYPE curtype IS REF CURSOR;  
  
   sql_stmt   CLOB;  
   src_cur    curtype;  
   curid      NUMBER;  
   desctab    DBMS_SQL.desc_tab;  
   colcnt     NUMBER;  
   namevar    VARCHAR2 (50);  
   numvar     NUMBER;  
   datevar    DATE;  
   empno      NUMBER            := 100;  
BEGIN  
   /* Construct the query, embedding the list of columns to be selected,  
      with a single bind variable.  
        
      NOTE: this kind of concatenation leaves you vulnerable to SQL injection!  
      Please read the section in this chapter on injection so that you can  
      make sure your application is not vulnerable.  
   */  
   sql_stmt :=  
         'SELECT '  
      || column_list_in  
      || ' FROM hr.employees WHERE department_id = :dept_id';  
  
   /* Open the cursor variable for this query, binding in the single value.  
      MUCH EASIER than using DBMS_SQL for the same operations!  
   */  
   OPEN src_cur FOR sql_stmt USING department_id_in;  
  
   /*  
   To fetch the data, however, I can no longer use the cursor variable,  
   since the number of elements fetched is unknown at complile time.  
     
   This is, however, a perfect fit for DBMS_SQL and the DESCRIBE_COLUMNS  
   procedure, so convert the cursor variable to a DBMS_SQL cursor number,  
   and then take the necessary, if tedious steps.  
   */  
   curid := DBMS_SQL.to_cursor_number (src_cur);  
     
   DBMS_SQL.describe_columns (curid, colcnt, desctab);  
  
   FOR indx IN 1 .. colcnt  
   LOOP  
      IF desctab (indx).col_type = 2  
      THEN  
         DBMS_SQL.define_column (curid, indx, numvar);  
      ELSIF desctab (indx).col_type = 12  
      THEN  
         DBMS_SQL.define_column (curid, indx, datevar);  
      ELSE  
         DBMS_SQL.define_column (curid, indx, namevar, 100);  
      END IF;  
   END LOOP;  
  
   WHILE DBMS_SQL.fetch_rows (curid) > 0  
   LOOP  
      FOR indx IN 1 .. colcnt  
      LOOP  
         DBMS_OUTPUT.put_line (desctab (indx).col_name || ' = ');  
  
         IF (desctab (indx).col_type = 2)  
         THEN  
            DBMS_SQL.COLUMN_VALUE (curid, indx, numvar);  
            DBMS_OUTPUT.put_line ('   ' || numvar);  
         ELSIF (desctab (indx).col_type = 12)  
         THEN  
            DBMS_SQL.COLUMN_VALUE (curid, indx, datevar);  
            DBMS_OUTPUT.put_line ('   ' || datevar);  
         ELSE /* Assume a string - of course, you cannot REALLY do that. */  
            DBMS_SQL.COLUMN_VALUE (curid, indx, namevar);  
            DBMS_OUTPUT.put_line ('   ' || namevar);  
         END IF;  
      END LOOP;  
   END LOOP;  
  
   DBMS_SQL.close_cursor (curid);  
END; 
/

BEGIN 
   show_data (column_list_in        => 'last_name, salary, hire_date' 
            , department_id_in      => 20 
             ); 
END; 
/

