/*
Uses DBMS_RANDOM to generate random integers and strings, but also ensures 
no duplicates and passes back results in a collection. More info on DBMS_RANDOM 
here: http://docs.oracle.com/database/121/ARPLS/d_random.htm#ARPLS040
*/

-- Randomizer Package Specfiication
-- You decide if you want distinct values or not.
CREATE OR REPLACE PACKAGE randomizer  
/*  
| Overview: Simple API to generate collections of random values, unique if desired. 
|  
| Author: Steven Feuerstein  
*/  
IS  
   TYPE integer_aat IS TABLE OF PLS_INTEGER  
      INDEX BY PLS_INTEGER;  
  
   TYPE date_aat IS TABLE OF DATE  
      INDEX BY PLS_INTEGER;  
  
   SUBTYPE maxvarchar2 IS VARCHAR2 (32767);  
  
   TYPE maxvarchar2_aat IS TABLE OF maxvarchar2  
      INDEX BY PLS_INTEGER;  
  
   TYPE maxvarchar2_by_string_aat IS TABLE OF maxvarchar2  
      INDEX BY maxvarchar2;  
  
   /* String types based on DBMS_RANDOM.STRING:  
      u - uppercase  
      l - lowercase  
      a - mixed case  
      x - mix of uppercase and digits  
      p - any printable character  
   */  
   FUNCTION random_strings (  
      count_in             IN   PLS_INTEGER DEFAULT 100  
    , min_length_in        IN   PLS_INTEGER DEFAULT 1  
    , max_length_in        IN   PLS_INTEGER DEFAULT 100  
    , string_type_in       IN   VARCHAR2  
            DEFAULT NULL                        /* any printable character */  
    , distinct_values_in   IN   BOOLEAN DEFAULT TRUE  
   )  
      RETURN maxvarchar2_aat;  
  
   FUNCTION random_integers (  
      count_in             IN   PLS_INTEGER DEFAULT 100  
    , min_value_in         IN   PLS_INTEGER DEFAULT 1  
    , max_value_in         IN   PLS_INTEGER DEFAULT 1000  
    , distinct_values_in   IN   BOOLEAN DEFAULT TRUE  
   )  
      RETURN integer_aat;  
  
   FUNCTION random_dates (  
      count_in             IN   PLS_INTEGER DEFAULT 100  
    , min_value_in         IN   DATE DEFAULT SYSDATE - 500  
    , max_value_in         IN   DATE DEFAULT SYSDATE + 500  
    , distinct_values_in   IN   BOOLEAN DEFAULT TRUE  
   )  
      RETURN date_aat;  
  
   PROCEDURE random_verifier (  
      count_in         IN   PLS_INTEGER DEFAULT 100  
    , min_length_in    IN   PLS_INTEGER DEFAULT 1  
    , max_length_in    IN   PLS_INTEGER DEFAULT 100  
    , string_type_in   IN   VARCHAR2 DEFAULT NULL  
    , min_integer_in   IN   PLS_INTEGER DEFAULT 1  
    , max_integer_in   IN   PLS_INTEGER DEFAULT 1000  
    , min_date_in      IN   DATE DEFAULT SYSDATE - 500  
    , max_date_in      IN   DATE DEFAULT SYSDATE + 500  
   );  
END randomizer; 
/

-- Randomizer Package Body
-- The DBMS_RANDOM package makes it easy.
CREATE OR REPLACE PACKAGE BODY randomizer  
/*  
| Overview: generates collections of random values  
|  
| Author: Steven Feuerstein  
*/  
IS  
   PROCEDURE span_assert (count_in IN PLS_INTEGER, span_in IN PLS_INTEGER)  
   IS  
   BEGIN  
      IF count_in > span_in  
      THEN  
         raise_application_error  
            (-20000  
           ,    'Random generation error: you have requested '  
             || count_in  
             || ' distinct random values, but your min-max specification allows for only '  
             || span_in  
             || ' distinct values.'  
            );  
      END IF;  
   END span_assert;  
  
   FUNCTION random_strings (  
      count_in             IN   PLS_INTEGER DEFAULT 100  
    , min_length_in        IN   PLS_INTEGER DEFAULT 1  
    , max_length_in        IN   PLS_INTEGER DEFAULT 100  
    , string_type_in       IN   VARCHAR2 DEFAULT NULL  
    , distinct_values_in   IN   BOOLEAN DEFAULT TRUE  
   )  
      RETURN maxvarchar2_aat  
   IS  
      l_value       maxvarchar2;  
      l_values      maxvarchar2_aat;  
      l_used        maxvarchar2_by_string_aat;  
      l_hit_count   PLS_INTEGER               DEFAULT 0;  
   BEGIN  
      -- span_assert (count_in, max_length_in - min_length_in);  
      WHILE (l_values.COUNT < count_in)  
      LOOP  
         l_value :=  
            DBMS_RANDOM.STRING (string_type_in  
                              , DBMS_RANDOM.VALUE (min_length_in  
                                                 , max_length_in  
                                                  )  
                               );  
  
         IF distinct_values_in  
         THEN  
            IF l_used.EXISTS (l_value)  
            THEN  
               l_hit_count := l_hit_count + 1;  
  
               IF l_hit_count >= count_in * 5  
               THEN  
                  raise_application_error  
                           (-20000  
                          ,    'Random generation error: Unable to generate '  
                            || count_in  
                            || ' distinct strings with min and max lengths '  
                            || min_length_in  
                            || ' and '  
                            || max_length_in  
                            || '.'  
                           );  
               END IF;  
            ELSE  
               /* Add a new one */  
               l_values (l_values.COUNT + 1) := l_value;  
               l_used (l_value) := l_value;  
            END IF;  
         ELSE  
            /* Add a new one */  
            l_values (l_values.COUNT + 1) := l_value;  
         END IF;  
      END LOOP;  
  
      RETURN l_values;  
   END random_strings;  
  
   FUNCTION random_integers (  
      count_in             IN   PLS_INTEGER DEFAULT 100  
    , min_value_in         IN   PLS_INTEGER DEFAULT 1  
    , max_value_in         IN   PLS_INTEGER DEFAULT 1000  
    , distinct_values_in   IN   BOOLEAN DEFAULT TRUE  
   )  
      RETURN integer_aat  
   IS  
      l_value       PLS_INTEGER;  
      l_values      integer_aat;  
      l_used        maxvarchar2_by_string_aat;  
      l_hit_count   PLS_INTEGER               DEFAULT 0;  
   BEGIN  
      span_assert (count_in, max_value_in - min_value_in + 1);  
  
      WHILE (l_values.COUNT < count_in)  
      LOOP  
         l_value := DBMS_RANDOM.VALUE (min_value_in, max_value_in);  
  
         IF distinct_values_in  
         THEN  
            IF l_used.EXISTS (l_value)  
            THEN  
               l_hit_count := l_hit_count + 1;  
  
               IF l_hit_count >= count_in * 5  
               THEN  
                  raise_application_error  
                           (-20000  
                          ,    'Random generation error: Unable to generate '  
                            || count_in  
                            || ' distinct integers with min and max values '  
                            || min_value_in  
                            || ' and '  
                            || max_value_in  
                            || '.'  
                           );  
               END IF;  
            ELSE  
               /* Add a new one */  
               l_values (l_values.COUNT + 1) := l_value;  
               l_used (l_value) := l_value;  
            END IF;  
         ELSE  
            /* Add a new one */  
            l_values (l_values.COUNT + 1) := l_value;  
         END IF;  
      END LOOP;  
  
      RETURN l_values;  
   END random_integers;  
  
   FUNCTION random_dates (  
      count_in             IN   PLS_INTEGER DEFAULT 100  
    , min_value_in         IN   DATE DEFAULT SYSDATE - 500  
    , max_value_in         IN   DATE DEFAULT SYSDATE + 500  
    , distinct_values_in   IN   BOOLEAN DEFAULT TRUE  
   )  
      RETURN date_aat  
   IS  
      l_values      date_aat;  
      l_date_diff   NUMBER                    := max_value_in - min_value_in;  
      l_value       DATE;  
      l_used        maxvarchar2_by_string_aat;  
      l_hit_count   PLS_INTEGER               DEFAULT 0;  
   BEGIN  
      span_assert (count_in, max_value_in - min_value_in + 1);  
  
      WHILE (l_values.COUNT < count_in)  
      LOOP  
         l_value := min_value_in + DBMS_RANDOM.VALUE (1, l_date_diff);  
  
         IF distinct_values_in  
         THEN  
            IF l_used.EXISTS (TO_CHAR (l_value, 'YYYYMMDDHH24MISS'))  
            THEN  
               l_hit_count := l_hit_count + 1;  
  
               IF l_hit_count >= count_in * 5  
               THEN  
                  raise_application_error  
                           (-20000  
                          ,    'Random generation error: Unable to generate '  
                            || count_in  
                            || ' distinct dates with min and max values '  
                            || min_value_in  
                            || ' and '  
                            || max_value_in  
                            || '.'  
                           );  
               END IF;  
            ELSE  
               /* Add a new one */  
               l_values (l_values.COUNT + 1) := l_value;  
               l_used (TO_CHAR (l_value, 'YYYYMMDDHH24MISS')) := l_value;  
            END IF;  
         ELSE  
            /* Add a new one */  
            l_values (l_values.COUNT + 1) := l_value;  
         END IF;  
      END LOOP;  
  
      RETURN l_values;  
   END random_dates;  
  
   PROCEDURE random_verifier (  
      count_in         IN   PLS_INTEGER DEFAULT 100  
    , min_length_in    IN   PLS_INTEGER DEFAULT 1  
    , max_length_in    IN   PLS_INTEGER DEFAULT 100  
    , string_type_in   IN   VARCHAR2 DEFAULT NULL  
    , min_integer_in   IN   PLS_INTEGER DEFAULT 1  
    , max_integer_in   IN   PLS_INTEGER DEFAULT 1000  
    , min_date_in      IN   DATE DEFAULT SYSDATE - 500  
    , max_date_in      IN   DATE DEFAULT SYSDATE + 500  
   )  
   IS  
      l_strings    maxvarchar2_aat;  
      l_integers   integer_aat;  
      l_dates      date_aat;  
   BEGIN  
      l_strings := random_strings (count_in, min_length_in, max_length_in);  
      l_integers :=  
                   random_integers (count_in, min_integer_in, max_integer_in);  
      l_dates := random_dates (count_in, min_date_in, max_date_in);  
      DBMS_OUTPUT.put_line ('Random Strings:');  
  
      FOR indx IN l_strings.FIRST .. l_strings.LAST  
      LOOP  
         DBMS_OUTPUT.put_line (l_strings (indx));  
      END LOOP;  
  
      DBMS_OUTPUT.put_line ('Random Integers:');  
  
      FOR indx IN l_integers.FIRST .. l_integers.LAST  
      LOOP  
         DBMS_OUTPUT.put_line (l_integers (indx));  
      END LOOP;  
  
      DBMS_OUTPUT.put_line ('Random Dates:');  
  
      FOR indx IN l_dates.FIRST .. l_dates.LAST  
      LOOP  
         DBMS_OUTPUT.put_line (TO_CHAR (l_dates (indx), 'YYYYMMDDHH24MISS'));  
      END LOOP;  
   END random_verifier;  
END randomizer; 
/

-- Generate Random Strings
DECLARE 
   l_strings   randomizer.maxvarchar2_aat; 
BEGIN 
   l_strings := 
      randomizer.random_strings (count_in                => 100 
                               , min_length_in           => 3 
                               , max_length_in           => 20 
                               , string_type_in          => 'x' 
                               , distinct_values_in      => TRUE 
                                ); 
 
   FOR indx IN 1 .. l_strings.COUNT 
   LOOP 
      DBMS_OUTPUT.put_line (l_strings (indx)); 
   END LOOP; 
END; 
/

-- Generate Random Integers
DECLARE 
   l_integers   randomizer.integer_aat; 
BEGIN 
   l_integers := 
      randomizer.random_integers (count_in                => 25 
                                , min_value_in           => 1 
                                , max_value_in           => 25 
                                , distinct_values_in      => TRUE 
                                 ); 
 
   FOR indx IN 1 .. l_integers.COUNT 
   LOOP 
      DBMS_OUTPUT.put_line (l_integers (indx)); 
   END LOOP; 
END; 
/

