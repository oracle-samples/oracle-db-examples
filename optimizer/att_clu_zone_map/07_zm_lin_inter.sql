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

PROMPT Observe how zone maps prune IO without
PROMPT the use of indexes

PROMPT Clean up first

DROP INDEX sales_loc_i
/
DROP INDEX sales_ac_loc_i
/
DROP MATERIALIZED ZONEMAP sales_ac_zmap
/
DROP MATERIALIZED ZONEMAP zmap$_sales_ac
/
ALTER TABLE sales_ac DROP CLUSTERING
/


PROMPT Create a zone map on the SALES_AC table
PROMPT using the same attribute clustering as before.
PROMPT We do not need to re-organise or move the
PROMPT data in the table as we are using the same
PROMPT clustering as before.

ALTER TABLE sales_ac 
ADD CLUSTERING BY LINEAR ORDER (location_id, product_id)
WITH MATERIALIZED ZONEMAP
/

PROMPT Observe the differences in the plan between
PROMPT the conventional SALES table and the 
PROMPT attribute clusterd table SALES_AC 
PROMPT with a zone map 

SELECT SUM(amount)
FROM   sales
WHERE  location_id = 50
/

SELECT * FROM TABLE(dbms_xplan.display_cursor);

SELECT SUM(amount)
FROM   sales_ac
WHERE  location_id = 50
/

SELECT * FROM TABLE(dbms_xplan.display_cursor);

SET AUTOTRACE ON STATISTICS

PROMPT Observe the IO differences for the zone mapped table.
PROMPT You may see Exadata that storage indexes
PROMPT eliminate some of the IO too since this
PROMPT feature can work in combination with zone maps.

PROMPT Conventional scan

SELECT SUM(amount)
FROM   sales
WHERE  location_id = 50
/

PROMPT With zone map

SELECT SUM(amount)
FROM   sales_ac
WHERE  location_id = 50
/

PROMPT Conventional scan

SELECT SUM(amount)
FROM   sales
WHERE  location_id = 50
AND    product_id = 10
/

PROMPT With zone map

SELECT SUM(amount)
FROM   sales_ac
WHERE  location_id = 50
AND    product_id = 10
/

PROMPT In this case we have used an attribute cluster with LINEAR ordering
PROMPT so we should use predicates on location_id or location_id and product_id
PROMPT A predicate on product_id alone will not prune effectively.
PROMPT INTERLEAVED ordering removes this limitation. 

PROMPT Conventional scan

SELECT SUM(amount)
FROM   sales
WHERE  product_id = 10
/

PROMPT With zone map - but no pruning on product_id alone

SELECT SUM(amount)
FROM   sales_ac
WHERE  product_id = 10
/

SET AUTOTRACE OFF

PROMPT Drop the attribute cluster
PROMPT Because we created the zone map at the same
PROMPT time as the cluster, the zone map will be dropped too

ALTER TABLE sales_ac DROP CLUSTERING
/
TRUNCATE TABLE sales_ac
/

--
PROMPT Enable interleaved join attribute clustering 
PROMPT on SALES_AC table.
PROMPT For the sake of example, create
PROMPT the zone map manually.
--
ALTER TABLE sales_ac 
ADD CLUSTERING sales_ac 
JOIN locations ON (sales_ac.location_id = locations.location_id) 
JOIN products  ON (sales_ac.product_id = products.product_id) 
BY INTERLEAVED ORDER ((locations.state, locations.county),products.product_name)
WITHOUT MATERIALIZED ZONEMAP
/

--
PROMPT Manually create the zone map
--

CREATE MATERIALIZED ZONEMAP sales_ac_zmap
AS
SELECT SYS_OP_ZONE_ID(s.rowid),
       MIN(l.state) min_state,
       MAX(l.state) max_state, 
       MIN(l.county) min_county, 
       MAX(l.county) max_county,
       MIN(p.product_name) min_prod, 
       MAX(p.product_name) max_prod
FROM sales_ac s, 
     locations l,
     products p
WHERE s.location_id = l.location_id(+)
AND   s.product_id = p.product_id(+)
GROUP BY SYS_OP_ZONE_ID(s.rowid)
/

--
PROMPT Insert data and observe that a 
PROMPT sorts and joins are performed to cluster
PROMPT data in the SALES_AC table.
PROMPT The direct path insert operation will maintain
PROMPT the zone map for us.
--
--
INSERT /*+ APPEND */ INTO sales_ac SELECT * FROM sales_source
/
SELECT * FROM TABLE(dbms_xplan.display_cursor)
/
COMMIT
/

EXECUTE dbms_stats.gather_table_stats(ownname=>NULL,tabname=>'sales_ac');

SET AUTOTRACE ON STATISTICS

PROMPT Compare the number of consistent gets of the
PROMPT zone map table against the standard table

PROMPT Conventional

SELECT SUM(amount)
FROM   sales
JOIN   locations  ON (sales.location_id = locations.location_id) 
WHERE  locations.state  = 'California'
/

PROMPT With zone map

SELECT SUM(amount)
FROM   sales_ac
JOIN   locations  ON (sales_ac.location_id = locations.location_id) 
WHERE  locations.state  = 'California'
/

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

PROMPT Since interleaved ordering was used to cluster the table,
PROMPT predicates can be used in various combinations. In particular
PROMPT pruning is still effective if product_name is used alone.
PROMPT Predicates for location dimensions do not need to be included.

PROMPT Conventional

SELECT SUM(amount)
FROM   sales
JOIN   products  ON (sales.product_id = products.product_id) 
WHERE  products.product_name  = 'DATEPALM'
/

PROMPT With zone map

SELECT SUM(amount)
FROM   sales_ac
JOIN   products  ON (sales_ac.product_id = products.product_id) 
WHERE  products.product_name  = 'DATEPALM'
/

SET AUTOTRACE OFF
