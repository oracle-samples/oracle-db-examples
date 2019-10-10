/*
One of the nicest things about nested tables is that you can compare two 
such collections for equality using nothing more than...the equality operator! 

Key things to remember: order of elements is not significant; if the collections 
have different numbers of elements, "=" returns FALSE; if they have the same 
number of elements, but at least one of the values in either collection is NULL, 
"=" returns NULL; two initialized, but empty collections are equal.
*/

-- What do you think will be displayed?
-- Before running this script, see if you can predict the outcome!
DECLARE
   TYPE nested_tab_t IS TABLE OF INTEGER;

   tab_1   nested_tab_t := nested_tab_t (1, 2, 3, 4, 5, 6, 7);
   tab_2   nested_tab_t := nested_tab_t (7, 6, 5, 4, 3, 2, 1);
   tab_3   nested_tab_t := nested_tab_t ();
   tab_4  nested_tab_t := nested_tab_t ();
   tab_5  nested_tab_t := nested_tab_t (null);
   tab_6  nested_tab_t := nested_tab_t (null);

   PROCEDURE check_for_equality (i_tab_1   IN nested_tab_t,
                                 i_tab_2   IN nested_tab_t)
   IS
      v_equal   BOOLEAN := i_tab_1 = i_tab_2;
   BEGIN
      DBMS_OUTPUT.put_line (
            'Equal? '
         || CASE
               WHEN v_equal IS NULL THEN 'null'
               WHEN v_equal THEN 'equal'
               ELSE 'not equal'
            END);
   END check_for_equality;
BEGIN
   check_for_equality (tab_1, tab_2);
   tab_1.EXTEND (1);
   check_for_equality (tab_1, tab_2);
   tab_2.EXTEND (1);
   check_for_equality (tab_1, tab_2);
   check_for_equality (tab_1, tab_3);
   check_for_equality (tab_3, tab_4);
   check_for_equality (tab_5, tab_6);
END;
/

