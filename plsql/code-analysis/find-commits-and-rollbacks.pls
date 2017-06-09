/* Data is gathered when you compile with this setting on:

ALTER SESSION SET plscope_settings='identifiers:all, statements:all'

*/

SELECT st.owner,
       st.object_name,
       st.object_type,
       st.line,
       src.text
  FROM all_statements st, all_source src
 WHERE     st.TYPE = 'COMMIT'
       AND st.object_name = src.name
       AND st.owner = src.owner
       AND st.line = src.line
ORDER BY st.owner,
         st.object_name,
         st.object_type   
/

SELECT st.owner,
       st.object_name,
       st.object_type,
       st.line,
       src.text
  FROM all_statements st, all_source src
 WHERE     st.TYPE = 'ROLLBACK'
       AND st.object_name = src.name
       AND st.owner = src.owner
       AND st.line = src.line
ORDER BY st.owner,
         st.object_name,
         st.object_type    
/

