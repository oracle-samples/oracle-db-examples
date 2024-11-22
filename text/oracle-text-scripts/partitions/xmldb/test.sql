CREATE TABLE trades_part OF XMLType
  XMLTYPE STORE AS BINARY XML
  VIRTUAL COLUMNS
    (trade_date AS (XMLCast(XMLQuery('/dataDocument/trade/tradeHeader/tradeDate'
                                   PASSING OBJECT_VALUE RETURNING CONTENT)
                          AS DATE)))
  PARTITION BY RANGE (trade_date)
  (PARTITION trades2005 VALUES LESS THAN (to_date('01-JAN-2005')),
               PARTITION trades2006 VALUES LESS THAN (to_date('01-JAN-2006')),
               PARTITION trades2007 VALUES LESS THAN (to_date('01-JAN-2007')),
               PARTITION trades2008 VALUES LESS THAN (to_date('01-JAN-2008')),
               PARTITION trades2009 VALUES LESS THAN (to_date('01-JAN-2009')),
               PARTITION trades2010 VALUES LESS THAN (to_date('01-JAN-2010')),
               PARTITION trades2011 VALUES LESS THAN (to_date('01-JAN-2011')),
               PARTITION trades2012 VALUES LESS THAN (to_date('01-JAN-2012')),
               PARTITION trades2013 VALUES LESS THAN (to_date('01-JAN-2013')),
               PARTITION trades2014 VALUES LESS THAN (to_date('01-JAN-2014')),
     PARTITION tradesMax VALUES LESS THAN (MAXVALUE));
 

CREATE INDEX trades_part_ctx_idx ON trades_part(OBJECT_VALUE)
   INDEXTYPE IS CTXSYS.CONTEXT
   PARAMETERS('memory 100M')
   Local;
