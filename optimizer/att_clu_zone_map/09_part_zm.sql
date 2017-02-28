-- DISCLAIMER:
-- This script is provided for educational purposes only. It is 
-- NOT supported by Oracle World Wide Technical Support.
-- The script has been tested and appears to work as intended.
-- You should always run new scripts initially 
-- on a test instance.

set timing off
set echo off
set lines 400 pages 1000
set feedback 1
set pause off
set echo on
set autotrace off
column plan_table_output format a150
set trims on

PROMPT Connect to the Attribute Clusters/Zone Map Schema
connect aczm12c/oracle_4U

--
PROMPT Drop the partitioned sales table (SALES_P) if it exists
--
DROP TABLE sales_p
/

--
PROMPT Create a range partitioned sales_p table
PROMPT with join attribute clustering and a zone map
--
CREATE TABLE sales_p (
  order_id           number(20)     not null
, order_item_number  number(3)      not null
, sale_date          date           not null
, delivered          date          
, sale_agent         varchar2(100)  not null
, product_id         number(10)     not null
, amount             number(10,2)   not null
, quantity           number(5)      not null
, location_id        number(20)     not null
, warehouse          varchar2(100)  not null
)
CLUSTERING sales_p 
JOIN locations ON (sales_p.location_id = locations.location_id) 
JOIN products  ON (sales_p.product_id = products.product_id) 
BY INTERLEAVED ORDER ((locations.state, locations.county),products.product_name, sales_p.delivered)
WITH MATERIALIZED ZONEMAP
PARTITION BY RANGE(sale_date) (
 PARTITION p1 VALUES LESS THAN (to_date('2005-01-01','YYYY-MM-DD'))
,PARTITION p2 VALUES LESS THAN (to_date('2010-01-01','YYYY-MM-DD'))
)
/

--
PROMPT Fill SALES_P with data
--
INSERT /*+ APPEND */ INTO sales_p SELECT * FROM sales_source
/
COMMIT
/

--
PROMPT Gather statistics on the table
--
EXECUTE dbms_stats.gather_table_stats(ownname=>NULL,tabname=>'sales_p');

--
PROMPT Confirm that the query plan includes a zone map filter
--
SELECT SUM(amount)
FROM   sales_p
JOIN   locations  ON (sales_p.location_id = locations.location_id) 
WHERE  locations.state  = 'California'
AND    locations.county  = 'Alpine County' 
/

SELECT * FROM TABLE(dbms_xplan.display_cursor);

column zone_id$ format 99999999999999

--
PROMPT Observe the zone id and the min and max order_id
PROMPT for each zone. The zone map state for each zone
PROMPT will be "0", which equates to "valid".
PROMPT Zone level "1" represents partitions and "0" represents zones.
PROMPT "Delivered" date correlates well with the partition key: "Sale Date".
PROMPT This is because we can expect a delivery to occur soon after a sale.
PROMPT So, because the delivered date correlates well with the partition key,
PROMPT each partition will contain a subset of "delivered" values.
PROMPT We should expect to be able to prune partitions from
PROMPT queries that filter on the "delivered" date.

SELECT zone_id$ ,
  min_4_delivered ,
  max_4_delivered , 
  zone_level$,
  zone_state$ ,
  zone_rows$
FROM ZMAP$_SALES_P;

PROMPT Observe that Pstart, Pstop shows, KEY(ZM),
PROMPT indicating the potential to prune partitions

SELECT SUM(amount)
FROM   sales_p
WHERE  delivered  between TO_DATE('18-SEP-00', 'DD-MON-YY') and TO_DATE('19-SEP-00', 'DD-MON-YY')
/

SELECT * FROM TABLE(dbms_xplan.display_cursor);

PROMPT Observe the effects of IO pruning
PROMPT Exadata storage indexes may effect the
PROMPT actual number of blocks read from storage cells. 
PROMPT However, using zone maps will ensure that pruning can
PROMPT ooccur in all appropriate circumstances.

SET AUTOTRACE ON STATISTICS

PROMPT Conventional table

SELECT SUM(amount)
FROM   sales
WHERE  delivered  between TO_DATE('18-SEP-00', 'DD-MON-YY') and TO_DATE('19-SEP-00', 'DD-MON-YY')
/

PROMPT With zone map

SELECT SUM(amount)
FROM   sales_p
WHERE  delivered  between TO_DATE('18-SEP-00', 'DD-MON-YY') and TO_DATE('19-SEP-00', 'DD-MON-YY')
/

SET AUTOTRACE OFF

