/*
PL/Scope is a powerful code analysis tool built into the PL/SQL compiler. 

This package helps you get started with PL/Scope. When you download and use 
in your own environment, you may want to replace USER_IDENTIFIERS with ALL_IDENTIFIERS, 
so that you can analyze code across schemas (but only code on which you have 
EXECUTE privileges, of course!).

-- Create the Package Specification
/*
These public procedures help you perform naming convention analysis on your code, 
find situations in which you have exposed variables in your package specification, 
identify all points in your subprogram where a given variable is modified, and point 
out exceptions you have defined but have not referenced (raised or handled).
*/

CREATE OR REPLACE PACKAGE plscope_helper  
/*  
   Helper package for PL/Scope and ALL_IDENTIFIERS  
  
   Author: Steven Feuerstein, steven@stevenfeuerstein.com  
  
   with assistance from Lucas Jellema of AMIS:  
   http://technology.amis.nl/blog/2584/enforcing-plsql-naming-conventions-through-a-simple-sql-query-using-oracle-11g-plscope  
  
   Modification History  
      Date          Change  
      12-APR-2010   created package from Lucas' original query  
  
   Notes:  
     * This package requires Oracle Database 11g Release 1 or higher.  
  
*/  
IS  
   /* Wild cards are supported for object names. */  
   PROCEDURE show_identifiers_in (  
      owner_in             IN VARCHAR2  
    , NAME_IN              IN VARCHAR2  
    , identifier_filter_in IN VARCHAR2 DEFAULT '%'  
    , usage_type_in        IN VARCHAR2 DEFAULT '%'  
   );  
  
   PROCEDURE should_contain (owner_in     IN VARCHAR2  
                           , NAME_IN      IN VARCHAR2  
                           , type_list_in IN VARCHAR2  
                           , filter_in    IN VARCHAR2  
                           , escape_in    IN VARCHAR2 DEFAULT '\'  
                           , title_in     IN VARCHAR2  
                            );  
  
   PROCEDURE should_start_with (owner_in     IN VARCHAR2  
                              , NAME_IN      IN VARCHAR2  
                              , type_list_in IN VARCHAR2  
                              , prefix_in    IN VARCHAR2  
                              , escape_in    IN VARCHAR2 DEFAULT '\'  
                               );  
  
   PROCEDURE should_end_with (owner_in     IN VARCHAR2  
                            , NAME_IN      IN VARCHAR2  
                            , type_list_in IN VARCHAR2  
                            , suffix_in    IN VARCHAR2  
                            , escape_in    IN VARCHAR2 DEFAULT '\'  
                             );  
  
   PROCEDURE exposed_package_data_in (owner_in IN VARCHAR2  
                                    , NAME_IN  IN VARCHAR2  
                                     );  
  
   PROCEDURE all_changes_to (owner_in         IN VARCHAR2  
                           , NAME_IN          IN VARCHAR2  
                           , variable_name_in IN VARCHAR2  
                            );  
  
   PROCEDURE unused_exceptions_in (owner_in IN VARCHAR2);  
END plscope_helper; 
/

-- The Package Body

CREATE OR REPLACE PACKAGE BODY plscope_helper  
IS  
   CURSOR all_objects_cur (  
      owner_in IN VARCHAR2  
    , NAME_IN  IN VARCHAR2  
   )  
   IS  
      SELECT DISTINCT /* Include with all_ owner, */ USER owner, object_name  
        FROM user_objects ao  
       WHERE     object_name <> 'PLSCOPE_HELPER'  
             AND object_name LIKE NAME_IN  
             /* Include with all_objects AND owner = owner_in */ 
             AND EXISTS  
                    (SELECT 'x'  
                       FROM user_identifiers i  
                      WHERE object_name = ao.object_name  
                            /* Include with all_identifiers AND owner = ao.owner */);  
  
   CURSOR idents_plus_source_cur (  
      owner_in        IN VARCHAR2  
    , NAME_IN         IN VARCHAR2  
    , ident_filter_in IN VARCHAR2  
    , usage_type_in   IN VARCHAR2  
   )  
   IS  
      SELECT i.name  
           , i.TYPE  
           , i.usage  
           , s.line  
           , i.object_type  
           , i.object_name  
           , s.text  
        FROM    user_identifiers i  
             JOIN  
                user_source s  
             ON (    s.name = i.object_name  
                 AND s.TYPE = i.object_type  
                 AND s.line = i.line)  
       WHERE     object_name = NAME_IN  
             /* Include with all_ AND owner = owner_in */ 
             AND (usage_type_in IS NULL OR i.usage LIKE usage_type_in)  
             AND (ident_filter_in IS NULL OR i.name LIKE ident_filter_in);  
  
   CURSOR globals_cur (  
      owner_in IN VARCHAR2  
    , NAME_IN  IN VARCHAR2  
   )  
   IS  
      SELECT i.name  
           , i.TYPE  
           , i.usage  
           , s.line  
           , i.object_type  
           , i.object_name  
           , s.text  
        FROM    user_identifiers i  
             JOIN  
                user_source s  
             ON (    s.name = i.object_name  
                 AND s.TYPE = i.object_type  
                 AND s.line = i.line)  
       WHERE     i.object_name = NAME_IN 
             /* Include with all_ AND i.owner = owner_in */ 
             AND i.TYPE = 'VARIABLE'  
             AND i.usage = 'DECLARATION'  
             AND i.object_type = 'PACKAGE';  
  
   TYPE idents_plus_source_t IS TABLE OF idents_plus_source_cur%ROWTYPE  
                                   INDEX BY PLS_INTEGER;  
  
   c_idents_plus_source_for_type   CONSTANT VARCHAR2 (32767)  
      := 'SELECT i.name, i.TYPE, i.usage, s.line, i.object_type, i.object_name, s.text  
        FROM user_identifiers i JOIN user_source s ON (  
                     s.name = i.object_name  
                 AND s.TYPE = i.object_type  
                 AND s.line = i.line)  
       WHERE /* Include with all_ i.owner = :owner AND */  
             i.object_name = :name AND i.type IN (:type)  
         AND LOWER (i.name) NOT LIKE :filter ESCAPE '':escape_char''' ;  
  
   PROCEDURE display_header (header_in           IN VARCHAR2  
                           , length_in           IN PLS_INTEGER DEFAULT 80  
                           , border_character_in IN VARCHAR2 DEFAULT '='  
                           , centered_in         IN BOOLEAN DEFAULT FALSE  
                            )  
   IS  
   BEGIN  
      DBMS_OUTPUT.  
       put_line (RPAD (border_character_in, length_in, border_character_in));  
      DBMS_OUTPUT.  
       put_line (  
         CASE  
            WHEN centered_in  
            THEN  
                  '|'  
               || LPAD (' ', (length_in - LENGTH (header_in)) / 2)  
               || header_in  
            ELSE  
               header_in  
         END  
      );  
      DBMS_OUTPUT.  
       put_line (RPAD (border_character_in, length_in, border_character_in));  
   END display_header;  
  
   PROCEDURE show_line (name  IN VARCHAR2  
                      , TYPE  IN VARCHAR2  
                      , usage IN VARCHAR2  
                      , line  IN VARCHAR2  
                      , text  IN VARCHAR2  
                       )  
   IS  
   BEGIN  
      DBMS_OUTPUT.  
       put_line (  
            RPAD (name, 30)  
         || RPAD (TYPE, 20)  
         || RPAD (usage, 15)  
         || RPAD (line, 6)  
         || text  
      );  
   END show_line;  
  
   PROCEDURE show_identifiers_in (  
      owner_in             IN VARCHAR2  
    , NAME_IN              IN VARCHAR2  
    , identifier_filter_in IN VARCHAR2 DEFAULT '%'  
    , usage_type_in        IN VARCHAR2 DEFAULT '%'  
   )  
   IS  
   BEGIN  
      FOR objrec IN all_objects_cur (owner_in, NAME_IN)  
      LOOP  
         display_header (  
               'All Identifiers in '  
            || objrec.owner  
            || '.'  
            || objrec.object_name  
         );  
         show_line ('Name', 'Type', 'Usage', 'Line#', 'Source');  
  
         FOR rec  
            IN idents_plus_source_cur (objrec.owner  
                                     , objrec.object_name  
                                     , identifier_filter_in  
                                     , usage_type_in  
                                      )  
         LOOP  
            show_line (rec.name, rec.TYPE, rec.usage, rec.line, rec.text);  
         END LOOP;  
      END LOOP;  
   END show_identifiers_in;  
  
   PROCEDURE should_contain (owner_in     IN VARCHAR2  
                           , NAME_IN      IN VARCHAR2  
                           , type_list_in IN VARCHAR2  
                           , filter_in    IN VARCHAR2  
                           , escape_in    IN VARCHAR2 DEFAULT '\'  
                           , title_in     IN VARCHAR2  
                            )  
   IS  
      l_query   VARCHAR2 (32767);  
      l_lines   idents_plus_source_t;  
   BEGIN  
      FOR objrec IN all_objects_cur (owner_in, NAME_IN)  
      LOOP  
         display_header (  
               'Identifiers of type ('  
            || type_list_in  
            || ') in '  
            || objrec.owner  
            || '.'  
            || objrec.object_name  
            || ' '  
            || title_in  
            || '"'  
            || filter_in  
            || '"'  
         );  
         show_line ('Name', 'Type', 'Usage', 'Line#', 'Source');  
         l_query :=  
            REPLACE (  
               REPLACE (c_idents_plus_source_for_type, ':type', type_list_in)  
             , ':escape_char'  
             , escape_in  
            );  
  
         EXECUTE IMMEDIATE l_query  
            BULK COLLECT INTO l_lines  
            USING /* Include with all_ objrec.owner, */ objrec.object_name, filter_in;  
  
         FOR indx IN 1 .. l_lines.COUNT  
         LOOP  
            show_line (l_lines (indx).name  
                     , l_lines (indx).TYPE  
                     , l_lines (indx).usage  
                     , l_lines (indx).line  
                     , l_lines (indx).text  
                      );  
         END LOOP;  
      END LOOP;  
   END should_contain;  
  
   PROCEDURE should_start_with (owner_in     IN VARCHAR2  
                              , NAME_IN      IN VARCHAR2  
                              , type_list_in IN VARCHAR2  
                              , prefix_in    IN VARCHAR2  
                              , escape_in    IN VARCHAR2 DEFAULT '\'  
                               )  
   IS  
      l_query   VARCHAR2 (32767);  
      l_lines   idents_plus_source_t;  
   BEGIN  
      should_contain (owner_in  
                    , NAME_IN  
                    , type_list_in  
                    , prefix_in || '%'  
                    , escape_in  
                    , 'should start with'  
                     );  
   END should_start_with;  
  
   PROCEDURE should_end_with (owner_in     IN VARCHAR2  
                            , NAME_IN      IN VARCHAR2  
                            , type_list_in IN VARCHAR2  
                            , suffix_in    IN VARCHAR2  
                            , escape_in    IN VARCHAR2 DEFAULT '\'  
                             )  
   IS  
   BEGIN  
      should_contain (owner_in  
                    , NAME_IN  
                    , type_list_in  
                    , '%' || suffix_in  
                    , escape_in  
                    , 'should end with'  
                     );  
   END should_end_with;  
  
   PROCEDURE exposed_package_data_in (owner_in IN VARCHAR2  
                                    , NAME_IN  IN VARCHAR2  
                                     )  
   IS  
   BEGIN  
      FOR objrec IN all_objects_cur (owner_in, NAME_IN)  
      LOOP  
         display_header (  
               'Global Variables Exposed in '  
            || objrec.owner  
            || '.'  
            || objrec.object_name  
         );  
         show_line ('Name', 'Type', 'Usage', 'Line#', 'Source');  
  
         FOR rec IN globals_cur (objrec.owner, objrec.object_name)  
         LOOP  
            show_line (rec.name, rec.TYPE, rec.usage, rec.line, rec.text);  
         END LOOP;  
      END LOOP;  
   END exposed_package_data_in;  
  
   PROCEDURE all_changes_to (owner_in         IN VARCHAR2  
                           , NAME_IN          IN VARCHAR2  
                           , variable_name_in IN VARCHAR2  
                            )  
   IS  
   BEGIN  
      FOR objrec IN all_objects_cur (owner_in, NAME_IN)  
      LOOP  
         display_header (  
               'All Changes Made to '  
            || objrec.owner  
            || '.'  
            || objrec.object_name  
            || '.'  
            || variable_name_in  
         );  
         show_line ('Name', 'Type', 'Usage', 'Line#', 'Source');  
  
         FOR rec  
            IN idents_plus_source_cur (objrec.owner  
                                     , objrec.object_name  
                                     , variable_name_in  
                                     , 'ASSIGNMENT'  
                                      )  
         LOOP  
            show_line (rec.name, rec.TYPE, rec.usage, rec.line, rec.text);  
         END LOOP;  
      END LOOP;  
   END all_changes_to;  
  
   PROCEDURE unused_exceptions_in (owner_in IN VARCHAR2)  
   IS  
      CURSOR exception_cur (  
         owner_in IN VARCHAR2  
      )  
      IS  
         WITH subprograms_with_exception  
                 AS (SELECT DISTINCT /* Include with all_ owner */ USER owner 
                                   , object_name  
                                   , object_type  
                                   , name  
                       FROM user_identifiers has_exc  
                      WHERE     /* Include with all_ has_exc.owner = owner_in AND */ 
                                has_exc.usage = 'DECLARATION'  
                            AND has_exc.TYPE = 'EXCEPTION'),  
              subprograms_with_raise_handle  
                 AS (SELECT DISTINCT /* Include with all_ owner */ USER owner  
                                   , object_name  
                                   , object_type  
                                   , name  
                       FROM user_identifiers with_rh  
                      WHERE     /* Include with all_ with_rh.owner = owner_in AND */ 
                                with_rh.usage = 'REFERENCE'  
                            AND with_rh.TYPE = 'EXCEPTION')  
         SELECT *  
           FROM subprograms_with_exception  
         MINUS  
         SELECT *  
           FROM subprograms_with_raise_handle;  
   BEGIN  
      display_header (  
         'Exceptions Declared and Not Used in Schema "' || owner_in || '"'  
      );  
  
      FOR objrec IN exception_cur (owner_in)  
      LOOP  
         DBMS_OUTPUT.  
          put_line (objrec.object_type || ' ' || objrec.object_name);  
      END LOOP;  
   END unused_exceptions_in;  
END plscope_helper; 
/

-- Example of Applying PLScope_Helper Package
-- Note the ALTER SESSION to turn on the PL/Scope feature!
ALTER SESSION SET plscope_settings='identifiers:all' ;

-- Example of Applying PLScope_Helper Package
-- Note the ALTER SESSION to turn on the PL/Scope feature!
CREATE OR REPLACE PACKAGE great_package 
IS 
   some_public_global_variable   NUMBER (10); 
   g_and_another_one             BOOLEAN; 
 
   PROCEDURE wonderful_program ( 
      input_param1_in   IN     NUMBER 
    ,  p_param2          IN OUT DATE); 
END great_package; 
/

-- Example of Applying PLScope_Helper Package
-- Note the ALTER SESSION to turn on the PL/Scope feature!
CREATE OR REPLACE PACKAGE BODY great_package 
IS 
   TYPE emprec IS RECORD 
   ( 
      l_name   VARCHAR2 (20) 
    ,  job      VARCHAR2 (20) 
   ); 
 
   g_emp      emprec; 
   global_1   POSITIVE; 
 
   PROCEDURE wonderful_program ( 
      input_param1_in   IN     NUMBER 
    ,  p_param2          IN OUT DATE) 
   IS 
      name       VARCHAR2 (100) := 'LUCAS'; 
      v_salary   NUMBER (10, 2); 
      b_job      VARCHAR2 (20); 
      hiredate   DATE; 
   BEGIN 
      GOTO all_done; 
 
      v_salary := 5432.12; 
      DBMS_OUTPUT.put_line ('My Name is ' || name); 
      DBMS_OUTPUT.put_line ('My Job is ' || b_job); 
      v_salary := v_salary * 2; 
      hiredate := SYSDATE - 1; 
 
     <<all_done>> 
      DBMS_OUTPUT.put_line ( 
         'I started this job on ' || hiredate); 
   END wonderful_program; 
END great_package; 
/

-- Example of Applying PLScope_Helper Package
-- Note the ALTER SESSION to turn on the PL/Scope feature!
BEGIN 
   plscope_helper.show_identifiers_in (USER 
                                     ,  'GREAT_PACKAGE'); 
 
   plscope_helper.all_changes_to (USER 
                                ,  'GREAT_PACKAGE' 
                                ,  'V_SALARY'); 
 
   plscope_helper.should_start_with ( 
      USER 
    ,  'GREAT_PACKAGE' 
    ,  q'['FORMAL IN', 'FORMAL IN OUT', 'FORMAL OUT']' 
    ,  'p_'); 
 
   plscope_helper.should_end_with (USER 
                                 ,  'GREAT_PACKAGE' 
                                 ,  q'['FORMAL IN OUT']' 
                                 ,  '_io'); 
 
   plscope_helper.exposed_package_data_in ( 
      USER 
    ,  'GREAT_PACKAGE'); 
END; 
/

