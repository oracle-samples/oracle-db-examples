/*
The string_tracker package allows you to keep track of whether a certain name has 
already been used within a particular list.

Besides hopefully being useful to you, it is a nice little demonstration of 
string-indexed associative arrays and nested collections (collections within collections)
*/

-- Create the Public API
CREATE OR REPLACE PACKAGE string_tracker 
IS 
   SUBTYPE maxvarchar2_t IS VARCHAR2 (32767); 
 
   SUBTYPE list_name_t IS maxvarchar2_t; 
 
   SUBTYPE value_string_t IS maxvarchar2_t; 
 
   PROCEDURE clear_all_lists; 
 
   PROCEDURE clear_list (list_name_in IN list_name_t); 
 
   PROCEDURE create_list ( 
      list_name_in IN list_name_t 
    , case_sensitive_in IN BOOLEAN DEFAULT FALSE 
    , overwrite_in IN BOOLEAN DEFAULT TRUE 
   ); 
 
   -- Is the string already in use? 
   FUNCTION string_in_use ( 
      list_name_in IN list_name_t 
    , value_string_in IN value_string_t 
   ) 
      RETURN BOOLEAN; 
 
   -- Mark this string as being used. 
   PROCEDURE mark_as_used ( 
      list_name_in IN list_name_t 
    , value_string_in IN value_string_t 
   ); 
END string_tracker; 
/

-- Imlpement the API
CREATE OR REPLACE PACKAGE BODY string_tracker 
/* 
Overview: string_tracker allows you to keep track of whether a 
certain name has already been used within a particular list. 
 
Author: Steven Feuerstein 
 
*/ 
IS 
   /* List of used strings - so why a collection of Booleans? 
      Because the string is the index value, so the element value 
      in the collection is of no importance. */ 
 
   TYPE used_aat IS TABLE OF BOOLEAN INDEX BY value_string_t; 
 
   /* No need to include the list name in the list record. 
      The index value that points to this record is the list name. */ 
   TYPE list_rt IS RECORD ( 
      case_sensitive   BOOLEAN 
    , list_of_values   used_aat 
   ); 
 
   TYPE list_of_lists_aat IS TABLE OF list_rt 
      INDEX BY list_name_t; 
 
   g_list_of_lists   list_of_lists_aat; 
 
   PROCEDURE assert (expr_in IN BOOLEAN, text_in IN VARCHAR2) 
   IS 
   BEGIN 
      IF NOT expr_in OR expr_in IS NULL 
      THEN 
         raise_application_error (-20000, text_in); 
      END IF; 
   END assert; 
 
   PROCEDURE clear_all_lists 
   IS 
   BEGIN 
      g_list_of_lists.DELETE; 
   END clear_all_lists; 
 
   PROCEDURE clear_list (list_name_in IN list_name_t) 
   IS 
   BEGIN 
      g_list_of_lists.DELETE (list_name_in); 
   END CLEAR_LIST; 
 
   PROCEDURE create_list ( 
      list_name_in        IN   list_name_t 
    , case_sensitive_in   IN   BOOLEAN DEFAULT FALSE 
    , overwrite_in        IN   BOOLEAN DEFAULT TRUE 
   ) 
   IS 
      l_create_list   BOOLEAN DEFAULT TRUE; 
      l_new_list      list_rt; 
   BEGIN 
      IF g_list_of_lists.EXISTS (list_name_in) 
      THEN 
         l_create_list := overwrite_in; 
      END IF; 
 
      IF l_create_list 
      THEN 
         l_new_list.case_sensitive := case_sensitive_in; 
         g_list_of_lists (list_name_in) := l_new_list; 
      END IF; 
   END create_list; 
 
   FUNCTION sensitized_value ( 
      list_name_in      IN   list_name_t 
    , value_string_in   IN   value_string_t 
   ) 
      RETURN value_string_t 
   IS 
   BEGIN 
      RETURN CASE g_list_of_lists (list_name_in).case_sensitive 
         WHEN TRUE 
            THEN value_string_in 
         ELSE UPPER (value_string_in) 
      END; 
   END sensitized_value; 
 
   FUNCTION string_in_use ( 
      list_name_in      IN   list_name_t 
    , value_string_in   IN   value_string_t 
   ) 
      RETURN BOOLEAN 
   IS 
   BEGIN 
      /* Don't assume inputs are valid! */ 
       
      assert (list_name_in IS NOT NULL 
            , 'You must provide a non-NULL name for your list!' 
             ); 
      assert (value_string_in IS NOT NULL 
            , 'You must provide a non-NULL string for tracking!' 
             ); 
      assert (g_list_of_lists.EXISTS (list_name_in) 
            ,    'You must create your list named "' 
              || list_name_in 
              || '" before you can use it.' 
             ); 
       
      RETURN g_list_of_lists (list_name_in).list_of_values.EXISTS 
                                            (sensitized_value (list_name_in 
                                                             , value_string_in 
                                                              ) 
                                            ); 
   END string_in_use; 
 
   PROCEDURE mark_as_used ( 
      list_name_in      IN   list_name_t 
    , value_string_in   IN   value_string_t 
   ) 
   IS 
   BEGIN 
      /* Don't assume inputs are valid! */ 
 
      assert (list_name_in IS NOT NULL 
            , 'You must provide a non-NULL name for your list!' 
             ); 
      assert (list_name_in IS NOT NULL 
            , 'You must provide a non-NULL name for your list!' 
             ); 
      assert (value_string_in IS NOT NULL 
            , 'You must provide a non-NULL string for tracking!' 
             ); 
      assert (g_list_of_lists.EXISTS (list_name_in) 
            ,    'You must create your list named "' 
              || list_name_in 
              || '" before you can use it.' 
             ); 
 
      g_list_of_lists (list_name_in).list_of_values 
                                            (sensitized_value (list_name_in 
                                                             , value_string_in 
                                                              ) 
                                            ) := TRUE; 
   END mark_as_used; 
END string_tracker;
/

-- Exercise the API
-- This is NOT a comprehensive regression test, but it demonstrates some key features. 
DECLARE 
   /* Create a constant with the list name to avoid multiple, 
      hard-coded references. Notice the use of the subtype 
      declared in the string_tracker package to declare the 
      list name. */ 
   c_list_name   CONSTANT string_tracker.list_name_t := 'outcomes'; 
BEGIN 
   /* Create the list, wiping out anything that was there before. */ 
   string_tracker.create_list (list_name_in        => c_list_name, 
                               case_sensitive_in   => FALSE, 
                               overwrite_in        => TRUE); 
 
   string_tracker.mark_as_used (list_name_in      => c_list_name, 
                                value_string_in   => 'abc'); 
 
   string_tracker.mark_as_used (list_name_in      => c_list_name, 
                                value_string_in   => 'def'); 
 
   IF string_tracker.string_in_use (list_name_in      => c_list_name, 
                                    value_string_in   => 'ABC') 
   THEN 
      DBMS_OUTPUT.put_line ('Case insenstive list - match found for ABC'); 
   END IF; 
 
   IF NOT string_tracker.string_in_use (list_name_in      => c_list_name, 
                                        value_string_in   => 'notinlist') 
   THEN 
      DBMS_OUTPUT.put_line ('No match found for notinlist'); 
   END IF; 
 
   /* Now case sensitive. */ 
   string_tracker.create_list (list_name_in        => c_list_name, 
                               case_sensitive_in   => TRUE, 
                               overwrite_in        => TRUE); 
   string_tracker.mark_as_used (list_name_in      => c_list_name, 
                                value_string_in   => 'abc'); 
 
   IF NOT string_tracker.string_in_use (list_name_in      => c_list_name, 
                                        value_string_in   => 'ABC') 
   THEN 
      DBMS_OUTPUT.put_line ('Case senstive list - match NOT found for ABC'); 
   END IF; 
EXCEPTION 
   WHEN OTHERS 
   THEN 
      DBMS_OUTPUT.put_line (DBMS_UTILITY.format_error_stack ()); 
END; 
/

