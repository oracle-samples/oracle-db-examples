/*
Here's a package that makes it easy to manage lists of lists, using a 
nested collection and a string indexed collection.
*/

-- Assertion Package Used Below
-- A helper package to assert that assumptions are valid. Nice, clean way to bullet-proof your code!
CREATE OR REPLACE PACKAGE assert 
IS 
   PROCEDURE assert ( 
      condition_in IN BOOLEAN 
    , msg_in IN VARCHAR2 
    , display_call_stack_in IN BOOLEAN DEFAULT FALSE 
    , null_means_failure_in IN BOOLEAN DEFAULT TRUE 
   );  
 
   PROCEDURE is_null ( 
      val_in IN VARCHAR2 
    , msg_in IN VARCHAR2 
    , display_call_stack_in IN BOOLEAN DEFAULT FALSE 
   ); 
 
   PROCEDURE is_not_null ( 
      val_in IN VARCHAR2 
    , msg_in IN VARCHAR2 
    , display_call_stack_in IN BOOLEAN DEFAULT FALSE 
   ); 
 
   PROCEDURE is_true ( 
      condition_in IN BOOLEAN 
    , msg_in IN VARCHAR2 
    , display_call_stack_in IN BOOLEAN DEFAULT FALSE 
   ); 
END assert; 
/

CREATE OR REPLACE PACKAGE BODY assert 
IS 
   PROCEDURE assert ( 
      condition_in IN BOOLEAN 
    , msg_in IN VARCHAR2 
    , display_call_stack_in IN BOOLEAN DEFAULT FALSE 
    , null_means_failure_in IN BOOLEAN DEFAULT TRUE 
   ) 
   IS 
   BEGIN 
      IF NOT condition_in 
         OR (null_means_failure_in AND condition_in IS NULL) 
      THEN 
         DBMS_OUTPUT.put_line ('ASSERTION VIOLATION! ' || msg_in); 
 
         /* Turned off until DBMS_UTILITY available in LiveSQL 
         IF display_call_stack_in 
         THEN 
            DBMS_OUTPUT.put_line ('Path taken to assertion violation:'); 
            DBMS_OUTPUT.put_line (DBMS_UTILITY.format_call_stack); 
         END IF; 
         */ 
 
         raise_application_error (-20000, 'ASSERTION VIOLATION! ' || msg_in); 
      END IF; 
   END; 
 
   PROCEDURE is_null ( 
      val_in IN VARCHAR2 
    , msg_in IN VARCHAR2 
    , display_call_stack_in IN BOOLEAN DEFAULT FALSE 
   ) 
   IS 
   BEGIN 
      assert (val_in IS NULL 
               , msg_in 
               , display_call_stack_in 
               , null_means_failure_in      => FALSE 
                ); 
   END is_null; 
 
   PROCEDURE is_not_null ( 
      val_in IN VARCHAR2 
    , msg_in IN VARCHAR2 
    , display_call_stack_in IN BOOLEAN DEFAULT FALSE 
   ) 
   IS 
   BEGIN 
      assert (val_in IS NOT NULL, msg_in, display_call_stack_in); 
   END is_not_null; 
 
   PROCEDURE is_true ( 
      condition_in IN BOOLEAN 
    , msg_in IN VARCHAR2 
    , display_call_stack_in IN BOOLEAN DEFAULT FALSE 
   ) 
   IS 
   BEGIN 
      assert (condition_in, msg_in, display_call_stack_in); 
   END is_true; 
END assert; 
/

-- Simple API to List-of-Lists Functionality
-- Heavy use of subtypes to improve readability and avoid repetitive hard-codings.
CREATE OR REPLACE PACKAGE string_tracker   
IS  
   SUBTYPE maxvarchar2_t IS VARCHAR2 (32767);  
  
   SUBTYPE list_name_t IS maxvarchar2_t;  
  
   SUBTYPE value_string_t IS maxvarchar2_t;  
  
   PROCEDURE clear_all_lists;  
  
   PROCEDURE empty_list (list_name_in IN list_name_t);  
  
   PROCEDURE create_list (list_name_in      IN list_name_t  
                        , case_sensitive_in IN BOOLEAN DEFAULT FALSE  
                        , overwrite_in      IN BOOLEAN DEFAULT TRUE  
                         );  
  
   -- Is the string already in use?  
   FUNCTION string_in_use (list_name_in    IN list_name_t  
                         , value_string_in IN value_string_t  
                          )  
      RETURN BOOLEAN;  
  
   -- Mark this string as being used.  
   PROCEDURE mark_as_used (list_name_in    IN list_name_t  
                         , value_string_in IN value_string_t  
                          );  
END string_tracker; 
/

-- Implementing String Tracker
-- Syntax for nested collections can be hard to read. I encourage you to 
-- take your time, go through this code line by line, and make sure you understand the moving parts.
CREATE OR REPLACE PACKAGE BODY string_tracker 
IS 
  c_doesnt_matter   CONSTANT BOOLEAN := NULL; 
 
   SUBTYPE who_cares_t IS BOOLEAN; 
 
   TYPE used_aat IS TABLE OF who_cares_t 
                       INDEX BY value_string_t; 
 
   TYPE list_rt IS RECORD (case_sensitive BOOLEAN, list_of_values used_aat); 
 
   TYPE list_of_lists_aat IS TABLE OF list_rt 
                                INDEX BY list_name_t; 
 
   g_list_of_lists   list_of_lists_aat; 
 
   PROCEDURE clear_all_lists 
   IS 
   BEGIN 
      g_list_of_lists.delete; 
   END clear_all_lists; 
 
   PROCEDURE empty_list (list_name_in IN list_name_t) 
   IS 
   BEGIN 
      g_list_of_lists.delete (list_name_in); 
   END empty_list; 
 
   PROCEDURE create_list (list_name_in      IN list_name_t 
                        , case_sensitive_in IN BOOLEAN DEFAULT FALSE 
                        , overwrite_in      IN BOOLEAN DEFAULT TRUE 
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
 
   FUNCTION sensitized_value (list_name_in    IN list_name_t 
                            , value_string_in IN value_string_t 
                             ) 
      RETURN value_string_t 
   IS 
   BEGIN 
      RETURN CASE g_list_of_lists (list_name_in).case_sensitive 
                WHEN TRUE THEN value_string_in 
                ELSE UPPER (value_string_in) 
             END; 
   END sensitized_value; 
 
   FUNCTION string_in_use (list_name_in    IN list_name_t 
                         , value_string_in IN value_string_t 
                          ) 
      RETURN BOOLEAN 
   IS 
      PROCEDURE initialize 
      IS 
      BEGIN 
         assert.is_not_null ( 
            list_name_in 
          , 'You must provide a non-NULL name for your list!' 
         ); 
         assert.is_not_null ( 
            value_string_in 
          , 'You must provide a non-NULL string for tracking!' 
         ); 
         assert.is_true ( 
            g_list_of_lists.EXISTS (list_name_in) 
          ,    'You must create your list named "' 
            || list_name_in 
            || '" before you can use it.' 
         ); 
      END initialize; 
   BEGIN 
      initialize; 
      RETURN g_list_of_lists(list_name_in).list_of_values.EXISTS ( 
                sensitized_value (list_name_in, value_string_in) 
             ); 
   END string_in_use; 
 
   PROCEDURE mark_as_used (list_name_in    IN list_name_t 
                         , value_string_in IN value_string_t 
                          ) 
   IS 
      PROCEDURE initialize 
      IS 
      BEGIN 
         assert.is_not_null ( 
            list_name_in 
          , 'You must provide a non-NULL name for your list!' 
         ); 
         assert.is_not_null ( 
            value_string_in 
          , 'You must provide a non-NULL string for tracking!' 
         ); 
         assert.is_true ( 
            g_list_of_lists.EXISTS (list_name_in) 
          ,    'You must create your list named "' 
            || list_name_in 
            || '" before you can use it.' 
         ); 
      END initialize; 
   BEGIN 
      initialize; 
      g_list_of_lists ( 
         list_name_in 
      ).list_of_values (sensitized_value (list_name_in, value_string_in)) := 
         c_doesnt_matter; 
   END mark_as_used; 
END string_tracker; 
/

-- Exercise the API
-- Create a constant with the list name to avoid multiple,
      hard-coded references. Notice the use of the subtype
      declared in the string_tracker package to declare the
      list name. 
DECLARE 
   c_list_name   CONSTANT string_tracker.list_name_t  := 'outcomes'; 
BEGIN 
   /* Create the list, wiping out anything that was there before. */ 
   string_tracker.create_list (list_name_in           => c_list_name 
                             , case_sensitive_in      => FALSE 
                             , overwrite_in           => TRUE 
                              ); 
   string_tracker.mark_as_used (list_name_in         => c_list_name 
                              , value_string_in      => 'abc' 
                               ); 
END;
/

