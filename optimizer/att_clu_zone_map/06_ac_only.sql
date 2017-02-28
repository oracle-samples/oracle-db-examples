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

PROMPT Connect to the Attribute Clusters/Zone Map Schema
connect aczm12c/oracle_4U

PROMPT The full potential of attribute clusters are realised
PROMPT when used in conjunction with zone maps, Exadata storage indexes
PROMPT and In-Memory min/max pruning. However, they also improve 
PROMPT index clustering. This is demonstrated here.

PROMPT Create indexes on location id for the standard SALES
PROMPT table and the attribute clustered SALES_AC table

CREATE INDEX sales_loc_i ON sales (location_id)
/

CREATE INDEX sales_ac_loc_i ON sales_ac (location_id)
/

column index_name format a40

PROMPT Observe the improved value of "Average Blocks Per Key"
PROMPT for the attribute clustered table. This will
PROMPT result in fewer consistend gets for table lookups from
PROMPT index range scans.

SELECT index_name, clustering_factor,avg_data_blocks_per_key
FROM   user_indexes
WHERE  index_name LIKE 'SALES%LOC%'
ORDER BY index_name
/

PROMPT Confirm that index range scans are occuring in both query examples
PROMPT Hints are used in this case because the table is relatively small
PROMPT so Exadata may choose a bloom filter plan.

SELECT /*+ INDEX(sales sales_loc_i) */ SUM(amount)
FROM   sales
JOIN   locations  ON (sales.location_id = locations.location_id) 
WHERE  locations.state  = 'California'
AND    locations.county = 'Alpine County' 
/
SELECT * FROM TABLE(dbms_xplan.display_cursor);

SELECT /*+ INDEX(sales_ac sales_ac_loc_i) */ SUM(amount)
FROM   sales_ac
JOIN   locations  ON (sales_ac.location_id = locations.location_id) 
WHERE  locations.state  = 'California'
AND    locations.county = 'Alpine County' 
/
SELECT * FROM TABLE(dbms_xplan.display_cursor);

PROMPT Run two test queries to cache all relevant data

SELECT SUM(amount)
FROM   sales
JOIN   locations  ON (sales.location_id = locations.location_id) 
WHERE  locations.state  = 'California'
AND    locations.county = 'Alpine County' 
/

SELECT SUM(amount)
FROM   sales_ac
JOIN   locations  ON (sales_ac.location_id = locations.location_id) 
WHERE  locations.state  = 'California'
AND    locations.county = 'Alpine County' 
/

PROMPT Run queries again and observe
PROMPT the reduced number of consistent 
PROMPT gets for the attribute cluster example.

SET AUTOTRACE ON STATISTICS

SELECT SUM(amount)
FROM   sales
JOIN   locations  ON (sales.location_id = locations.location_id) 
WHERE  locations.state  = 'California'
AND    locations.county = 'Alpine County' 
/

SELECT SUM(amount)
FROM   sales_ac
JOIN   locations  ON (sales_ac.location_id = locations.location_id) 
WHERE  locations.state  = 'California'
AND    locations.county = 'Alpine County' 
/

SET AUTOTRACE OFF

PROMPT Drop the test indexes

DROP INDEX sales_loc_i
/

DROP INDEX sales_ac_loc_i
/


