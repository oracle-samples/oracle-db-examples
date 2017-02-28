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
column plan_table_output format a150
set trims on

PROMPT Connect to the Attribute Clusters/Zone Map Schema
connect aczm12c/oracle_4U

PROMPT Clean up

ALTER TABLE sales_ac DROP CLUSTERING 
/
DROP MATERIALIZED ZONEMAP sales_ac_zmap
/
DROP MATERIALIZED ZONEMAP  zmap$_sales_ac
/

PROMPT Cluster the table again

ALTER TABLE sales_ac 
ADD CLUSTERING sales_ac 
JOIN locations ON (sales_ac.location_id = locations.location_id) 
JOIN products  ON (sales_ac.product_id = products.product_id) 
BY INTERLEAVED ORDER ((locations.state, locations.county), products.product_name, sales_ac.location_id)
WITHOUT MATERIALIZED ZONEMAP
/

PROMPT Since we have changed the clustering columns, we need to
PROMPT re-organize the table. This can be achieved using a move operation.

ALTER TABLE sales_ac MOVE
/

PROMPT
PROMPT Manually create the zone map.
PROMPT

CREATE MATERIALIZED ZONEMAP sales_ac_zmap
AS
SELECT SYS_OP_ZONE_ID(s.rowid),
       MIN(l.state) min_state,
       MAX(l.state) max_state, 
       MIN(l.county) min_county, 
       MAX(l.county) max_county,
       MIN(p.product_name) min_prod, 
       MAX(p.product_name) max_prod,
       MIN(s.location_id) min_loc,
       MAX(s.location_id) max_loc
FROM sales_ac s, 
     locations l,
     products p
WHERE s.location_id = l.location_id(+)
AND   s.product_id = p.product_id(+)
GROUP BY SYS_OP_ZONE_ID(s.rowid)
/

PROMPT Observe that we are achieving reduced IO for
PROMPT compared agains the non-zone mapped table (sales)

SET AUTOTRACE ON STATISTICS

PROMPT Conventional

SELECT SUM(amount)
FROM   sales
JOIN   locations  ON (sales.location_id = locations.location_id) 
WHERE  locations.state  = 'California'
AND    locations.county = 'Alpine County' 
/

PROMPT With zone map

SELECT SUM(amount)
FROM   sales_ac
JOIN   locations  ON (sales_ac.location_id = locations.location_id) 
WHERE  locations.state  = 'California'
AND    locations.county = 'Alpine County' 
/

PROMPT Conventional

SELECT SUM(amount)
FROM   sales
WHERE  location_id = 1000
/

PROMPT With zone map

SELECT SUM(amount)
FROM   sales_ac
WHERE  location_id = 1000
/

SET AUTOTRACE OFF

--
PROMPT Scan and join pruning
--
SELECT SUM(amount)
FROM   sales_ac
JOIN   locations  ON (sales_ac.location_id = locations.location_id) 
WHERE  locations.state  = 'California'
AND    locations.county = 'Alpine County' 
/

SELECT * FROM TABLE(dbms_xplan.display_cursor);

PROMPT Create an index on SALES_AC LOCATION_ID

CREATE  INDEX sales_ac_loc_i on sales_ac(location_id) 
/
CREATE  INDEX sales_loc_i on sales(location_id) 
/

--
PROMPT Index rowids can be pruned by zone 
--
SELECT sum(amount) 
FROM   sales_ac
WHERE  location_id = 1000
AND    order_item_number = 1
/

SELECT * FROM TABLE(dbms_xplan.display_cursor);

DROP  INDEX sales_ac_loc_i
/
DROP  INDEX sales_loc_i
/



