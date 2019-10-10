CREATE OR REPLACE TYPE numbers_t IS TABLE OF NUMBER;
/

CREATE OR REPLACE PACKAGE pipeline
IS
   CURSOR refcur_c
   IS
      SELECT line FROM all_source;

   TYPE refcur_t IS REF CURSOR
      RETURN refcur_c%ROWTYPE;

   FUNCTION double_values (dataset refcur_t)
      RETURN numbers_t
      PIPELINED;
END pipeline;
/

/*
In addition to using the PIPELINED keyword in the header,
you use the PIPE ROW statement to send the value back to
the calling query, asynchronous to the function actually 
finishing and returning control.

Notice also that the RETURN statement returns nothing but
control, since all the data has already been passed back.
*/

CREATE OR REPLACE PACKAGE BODY pipeline
IS
   FUNCTION double_values (dataset refcur_t)
      RETURN numbers_t
      PIPELINED
   IS
      l_number   NUMBER;
   BEGIN
      LOOP
         FETCH dataset INTO l_number;

         EXIT WHEN dataset%NOTFOUND;

         PIPE ROW (l_number * 2);
      END LOOP;

      CLOSE dataset;

      RETURN;
   END;
END pipeline;
/

/*
Notice that a query is passed as a parameter to the function. This is not
a *string* (dynamic SQL). It is the query itself, which is then encased
within a CURSOR function call, which returns a cursor variable that is
actually passed to the body of the function for fetching.
*/

SELECT *
  FROM TABLE (pipeline.double_values (
                 CURSOR (SELECT line
                           FROM all_source
                          WHERE ROWNUM < 10)))
/