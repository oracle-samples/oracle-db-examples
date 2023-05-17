/*
The "in tab" procedure displays what's in a table, using DBMS_SQL and method 4 dynamic SQL. 
That is, I do not know at the time I compile my code how many columns I will displaying. 
Most dynamic SQL method 4 is more complicated than this, so it serves as a nice introduction. 
Much of the code volume has to do with formatting, but I also like to use this as an 
example of relying on nested subprograms to make code much more readable. 

NOTE: this procedure is vulnerable to SQL injection. 
      Users should NEVER be allowed to pass inputs to program like this directly!
*/

CREATE OR REPLACE PROCEDURE intab (table_in          IN VARCHAR2, 
                                   where_in          IN VARCHAR2 DEFAULT NULL, 
                                   colname_like_in   IN VARCHAR2 := '%') 
   /* 
   | Demonstration of method 4 dynamic SQL with DBMS_SQL: 
   |   Show the contents "in" a "tab"le - intab. 
   |   Only supports number, date, string column types. 
   | 
   | Oracle Database 11g version utilizes DBMS_SQL.to_cursor_number 
   | to greatly simplify the code. 
   | 
   | Author: Steven Feuerstein, steven.feuerstein@oracle.com 
   */ 
   AUTHID CURRENT_USER 
IS 
   -- Avoid repetitive "maximum size" declarations for VARCHAR2 variables. 
   SUBTYPE max_varchar2_t IS VARCHAR2 (32767); 
 
   -- Minimize size of a string column. 
   c_min_length   CONSTANT PLS_INTEGER := 10; 
 
   -- Collection to hold the column information for this table. 
   TYPE columns_tt IS TABLE OF all_tab_columns%ROWTYPE 
      INDEX BY PLS_INTEGER; 
 
   l_columns               columns_tt; 
   -- Open a cursor for use by DBMS_SQL subprograms throughout this procedure. 
   l_cursor                INTEGER; 
   -- 
   -- Formatting and SELECT elements used throughout the program. 
   l_header                max_varchar2_t; 
   l_select_list           max_varchar2_t; 
   g_row_line_length       INTEGER := 0; 
 
   /* Utility functions that determine the "family" of the column datatype. 
   They do NOT comprehensively cover the datatypes supported by Oracle. 
   You will need to expand on these programs if you want your version of 
   intab to support a wider range of datatypes. 
   */ 
 
   FUNCTION is_string (columns_in IN columns_tt, row_in IN INTEGER) 
      RETURN BOOLEAN 
   IS 
   BEGIN 
      RETURN (columns_in (row_in).data_type IN ('CHAR', 'VARCHAR2', 'VARCHAR')); 
   END; 
 
   FUNCTION is_number (columns_in IN columns_tt, row_in IN INTEGER) 
      RETURN BOOLEAN 
   IS 
   BEGIN 
      RETURN (columns_in (row_in).data_type IN ('FLOAT', 'INTEGER', 'NUMBER')); 
   END; 
 
   FUNCTION is_date (columns_in IN columns_tt, row_in IN INTEGER) 
      RETURN BOOLEAN 
   IS 
   BEGIN 
      RETURN (columns_in (row_in).data_type IN ('DATE', 'TIMESTAMP')); 
   END; 
 
   PROCEDURE load_column_information ( 
      select_list_io   IN OUT NOCOPY VARCHAR2, 
      header_io        IN OUT NOCOPY VARCHAR2, 
      columns_io       IN OUT NOCOPY columns_tt) 
   IS 
      l_dot_location   PLS_INTEGER; 
      l_owner          VARCHAR2 (100); 
      l_table          VARCHAR2 (100); 
      l_index          PLS_INTEGER; 
      -- 
      no_such_table    EXCEPTION; 
      PRAGMA EXCEPTION_INIT (no_such_table, -942); 
   BEGIN 
      -- Separate the schema and table names, if both are present. 
      l_dot_location := INSTR (table_in, '.'); 
 
      IF l_dot_location > 0 
      THEN 
         l_owner := SUBSTR (table_in, 1, l_dot_location - 1); 
         l_table := SUBSTR (table_in, l_dot_location + 1); 
      ELSE 
         l_owner := USER; 
         l_table := table_in; 
      END IF; 
 
      -- Retrieve all the column information into a collection of records. 
 
      SELECT * 
        BULK COLLECT INTO columns_io 
        FROM all_tab_columns 
       WHERE     owner = l_owner 
             AND table_name = l_table 
             AND column_name LIKE NVL (colname_like_in, '%'); 
 
      l_index := columns_io.FIRST; 
 
      IF l_index IS NULL 
      THEN 
         RAISE no_such_table; 
      ELSE 
         /* Add each column to the select list, calculate the length needed 
         to display each column, and also come up with the total line length. 
         Again, please note that the datatype support here is quite limited. 
         */ 
 
         WHILE (l_index IS NOT NULL) 
         LOOP 
            IF select_list_io IS NULL 
            THEN 
               select_list_io := columns_io (l_index).column_name; 
            ELSE 
               select_list_io := 
                  select_list_io || ', ' || columns_io (l_index).column_name; 
            END IF; 
 
            IF is_string (columns_io, l_index) 
            THEN 
               columns_io (l_index).data_length := 
                  GREATEST ( 
                     LEAST (columns_io (l_index).data_length, c_min_length), 
                     LENGTH (columns_io (l_index).column_name)); 
            ELSIF is_date (columns_io, l_index) 
            THEN 
               columns_io (l_index).data_length := 
                  GREATEST (c_min_length, 
                            LENGTH (columns_io (l_index).column_name)); 
            ELSIF is_number (columns_io, l_index) 
            THEN 
               columns_io (l_index).data_length := 
                  GREATEST (NVL (columns_io (l_index).data_precision, 38), 
                            LENGTH (columns_io (l_index).column_name)); 
            END IF; 
 
            g_row_line_length := 
               g_row_line_length + columns_io (l_index).data_length + 1; 
            -- 
            -- Construct column header line incrementally. 
            header_io := 
                  header_io 
               || ' ' 
               || RPAD (columns_io (l_index).column_name, 
                        columns_io (l_index).data_length); 
            l_index := columns_io.NEXT (l_index); 
         END LOOP; 
      END IF; 
   END load_column_information; 
 
   PROCEDURE report_error (text_in IN VARCHAR2, cursor_io IN OUT INTEGER) 
   IS 
   BEGIN 
      IF DBMS_SQL.is_open (cursor_io) 
      THEN 
         DBMS_SQL.close_cursor (cursor_io); 
      END IF; 
 
      DBMS_OUTPUT.put_line (text_in); 
      DBMS_OUTPUT.put_line (DBMS_UTILITY.format_error_backtrace); 
   END; 
 
   PROCEDURE construct_and_open_cursor (select_list_in   IN     VARCHAR2, 
                                        cursor_out          OUT INTEGER) 
   IS 
      l_query          max_varchar2_t; 
      l_where_clause   max_varchar2_t := LTRIM (where_in); 
      l_cursor         SYS_REFCURSOR; 
   BEGIN 
      -- Construct a where clause if a value was specified. 
 
      IF l_where_clause IS NOT NULL 
      THEN 
         -- 
 
         IF (    l_where_clause NOT LIKE 'GROUP BY%' 
             AND l_where_clause NOT LIKE 'ORDER BY%') 
         THEN 
            l_where_clause := 'WHERE ' || LTRIM (l_where_clause, 'WHERE'); 
         END IF; 
      END IF; 
 
      -- Assign the dynamic string to a local variable so that it can be 
      -- easily used to report an error. 
      l_query := 
            'SELECT ' 
         || select_list_in 
         || '  FROM ' 
         || table_in 
         || ' ' 
         || l_where_clause; 
      DBMS_OUTPUT.put_line (l_querY); 
 
      -- 11.1 DBMS_SQL enhancement: convert to cursor variable. 
      OPEN l_cursor FOR l_query; 
 
      cursor_out := DBMS_SQL.to_cursor_number (l_cursor); 
   EXCEPTION 
      WHEN OTHERS 
      THEN 
         report_error ('Error constructing and opening cursor: ' || l_query, 
                       cursor_out); 
         RAISE; 
   END; 
 
   PROCEDURE define_columns_and_execute (cursor_io    IN OUT INTEGER, 
                                         columns_in   IN     columns_tt) 
   IS 
      l_index      PLS_INTEGER; 
      l_feedback   PLS_INTEGER; 
   BEGIN 
      /* 
      DBMS_SQL.DEFINE_COLUMN 
      Before executing the query, I need to tell DBMS_SQL the datatype 
      of each the columns being selected in the query. I simply pass 
      a literal of the appropriate type to an overloading of 
      DBMS_SQL.DEFINE_COLUMN. With string types, I need to also specify 
      the maximum length of the value. 
      */ 
      l_index := columns_in.FIRST; 
 
      WHILE (l_index IS NOT NULL) 
      LOOP 
         IF is_string (columns_in, l_index) 
         THEN 
            DBMS_SQL.define_column (cursor_io, 
                                    l_index, 
                                    'a', 
                                    columns_in (l_index).data_length); 
         ELSIF is_number (columns_in, l_index) 
         THEN 
            DBMS_SQL.define_column (cursor_io, l_index, 1); 
         ELSIF is_date (columns_in, l_index) 
         THEN 
            DBMS_SQL.define_column (cursor_io, l_index, SYSDATE); 
         END IF; 
 
         l_index := columns_in.NEXT (l_index); 
      END LOOP; 
   EXCEPTION 
      WHEN OTHERS 
      THEN 
         report_error ('Error defining columns', cursor_io); 
         RAISE; 
   END; 
 
   PROCEDURE build_and_display_output (header_in    IN     VARCHAR2, 
                                       cursor_io    IN OUT INTEGER, 
                                       columns_in   IN     columns_tt) 
   IS 
      -- Used to hold the retrieved column values. 
      l_string_value     VARCHAR2 (2000); 
      l_number_value     NUMBER; 
      l_date_value       DATE; 
      -- 
      l_feedback         INTEGER; 
      l_index            PLS_INTEGER; 
      l_one_row_string   max_varchar2_t; 
 
      -- Formatting for the output of the header information 
 
      PROCEDURE display_header 
      IS 
         l_border   max_varchar2_t := RPAD ('-', g_row_line_length, '-'); 
 
         FUNCTION centered_string (string_in   IN VARCHAR2, 
                                   length_in   IN INTEGER) 
            RETURN VARCHAR2 
         IS 
            len_string   INTEGER := LENGTH (string_in); 
         BEGIN 
            IF len_string IS NULL OR length_in <= 0 
            THEN 
               RETURN NULL; 
            ELSE 
               RETURN    RPAD (' ', (length_in - len_string) / 2 - 1) 
                      || LTRIM (RTRIM (string_in)); 
            END IF; 
         END centered_string; 
      BEGIN 
         DBMS_OUTPUT.put_line (l_border); 
         DBMS_OUTPUT.put_line ( 
            centered_string ('Contents of ' || table_in, g_row_line_length)); 
         DBMS_OUTPUT.put_line (l_border); 
         DBMS_OUTPUT.put_line (l_header); 
         DBMS_OUTPUT.put_line (l_border); 
      END display_header; 
   BEGIN 
      display_header; 
 
      /* 
         DBMS_SQL.FETCH_ROWS 
         Fetch a row, and return the numbers of rows fetched. 
         When 0, we are done. 
      */ 
      WHILE DBMS_SQL.fetch_rows (cursor_io) > 0 
      LOOP 
         l_one_row_string := NULL; 
         l_index := columns_in.FIRST; 
 
         WHILE (l_index IS NOT NULL) 
         LOOP 
            /* 
            DBMS_SQL.COLUMN_VALUE 
            Retrieve each column value in the current row, 
            deposit it into a variable of the appropriate type, 
            then convert to a string and concatenate to the 
            full line variable. 
            */ 
 
            IF is_string (columns_in, l_index) 
            THEN 
               DBMS_SQL.COLUMN_VALUE (cursor_io, l_index, l_string_value); 
            ELSIF is_number (columns_in, l_index) 
            THEN 
               DBMS_SQL.COLUMN_VALUE (cursor_io, l_index, l_number_value); 
               l_string_value := TO_CHAR (l_number_value); 
            ELSIF is_date (columns_in, l_index) 
            THEN 
               DBMS_SQL.COLUMN_VALUE (cursor_io, l_index, l_date_value); 
               l_string_value := TO_CHAR (l_date_value); 
            END IF; 
 
            l_one_row_string := 
                  l_one_row_string 
               || ' ' 
               || RPAD (NVL (l_string_value, ' '), 
                        columns_in (l_index).data_length); 
            l_index := columns_in.NEXT (l_index); 
         END LOOP; 
 
         DBMS_OUTPUT.put_line (l_one_row_string); 
      END LOOP; 
   EXCEPTION 
      WHEN OTHERS 
      THEN 
         report_error ( 
            'Error displaying output; last row = ' || l_one_row_string, 
            cursor_io); 
   END; 
BEGIN 
   load_column_information (l_select_list, l_header, l_columns); 
   construct_and_open_cursor (l_select_list, l_cursor); 
   define_columns_and_execute (l_cursor, l_columns); 
   build_and_display_output (l_header, l_cursor, l_columns); 
END intab; 
/

BEGIN  
   intab ('HR.DEPARTMENTS',  
          where_in          => 'department_name like ''%io%''',  
          colname_like_in   => '%NAME%');  
END; 
/

BEGIN  
   intab ('HR.EMPLOYEES',  
          where_in          => 'department_id = 80',  
          colname_like_in   => '%NAME%');  
END; 
/

