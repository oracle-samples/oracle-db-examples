/*
The stockpivot function takes one row from the stock table
and returns two rows to be stored in the ticker table
*/

CREATE TABLE  stocktable (
  ticker VARCHAR2(20),
  trade_date DATE,
  open_price NUMBER,
  close_price NUMBER
);

BEGIN
   FOR indx IN 1 .. 100000
   LOOP
      -- Might as well be optimistic!
      INSERT INTO stocktable
           VALUES ('STK' || indx, SYSDATE, indx, indx + 15);
   END LOOP;

   COMMIT;
END;
/

CREATE TYPE tickertype AS OBJECT (
   ticker      VARCHAR2 (20)
  ,pricedate   DATE
  ,pricetype   VARCHAR2 (1)
  ,price       NUMBER
);
/

CREATE TYPE tickertypeset AS TABLE OF tickertype;
/

CREATE TABLE tickertable
(
  ticker VARCHAR2(20),
  pricedate DATE,
  pricetype VARCHAR2(1),
  price NUMBER
)
/

CREATE OR REPLACE PACKAGE pipeline
IS
   TYPE ticker_tt IS TABLE OF tickertype;

   FUNCTION stockpivot_pl (dataset refcur_pkg.refcur_t)
      RETURN tickertypeset PIPELINED;
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
   FUNCTION stockpivot_pl (dataset refcur_pkg.refcur_t)
      RETURN tickertypeset PIPELINED
   IS
      out_obj   tickertype     := tickertype (NULL, NULL, NULL, NULL);
      in_rec    dataset%ROWTYPE;
   BEGIN
      LOOP
         FETCH dataset
          INTO in_rec;

         EXIT WHEN dataset%NOTFOUND;
         -- first row
         out_obj.ticker := in_rec.ticker;
         out_obj.pricetype := 'O';
         out_obj.price := in_rec.open_price;
         out_obj.pricedate := in_rec.trade_date;
         PIPE ROW (out_obj);
         -- second row
         out_obj.pricetype := 'C';
         out_obj.price := in_rec.close_price;
         out_obj.pricedate := in_rec.trade_date;
         PIPE ROW (out_obj);
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

INSERT INTO tickertable
   SELECT *
     FROM TABLE (pipeline.stockpivot_pl (CURSOR (SELECT *
                                                   FROM stocktable)))
    WHERE ROWNUM < 10;