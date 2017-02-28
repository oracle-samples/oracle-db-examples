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

PURGE recyclebin
/

PROMPT     Drop SALES table (if it exists)
DROP TABLE sales
/

PROMPT     Drop SALES_AC table (if it exists)
DROP TABLE sales_ac
/

--
PROMPT Create the SALES fact table
PROMPT This table will not have attribute clustering 
PROMPT or zone maps. We will use it to compare with
PROMPT an attribute clustered table.
--
CREATE TABLE sales
AS 
SELECT * FROM sales_source
WHERE 1 = -1
/

--
PROMPT Create a SALES_AC fact table
PROMPT The data will be the same as SALES 
PROMPT but it will be used to demontrate 
PROMPT attribute clustering and zone maps
PROMPT in comparison to the standard SALES table.
--
CREATE TABLE sales_ac
AS 
SELECT * FROM sales_source
WHERE 1 = -1
/

--
PROMPT Here we enable linear ordered attribute clustering
PROMPT We will simply order rows by location_id, product_id
PROMPT To see the effects of attribute clustering in 
PROMPT isolation, we will not create a zone map.
--
ALTER TABLE sales_ac 
ADD CLUSTERING BY LINEAR ORDER (location_id, product_id)
WITHOUT MATERIALIZED ZONEMAP
/

set timing on
--
PROMPT Insert data into standard table
--
INSERT /*+ APPEND */ INTO sales SELECT * FROM sales_source
/
--
PROMPT Observe that insert plan is a simple insert
--
SELECT * FROM TABLE(dbms_xplan.display_cursor)
/
COMMIT
/

--
PROMPT Insert data into attribute clustered table.
PROMPT We must use a direct path operation to make
PROMPT use of attribute clustering. 
PROMPT In real systems we will probably insert in 
PROMPT multiple batches: each batch of inserts will be
PROMPT ordered appropriately. Later on, 
PROMPT if we want to re-order all rows into
PROMPT tightly grouped zones we can, for example, use
PROMPT partitioning and MOVE PARTITION to do this.
PROMPT
PROMPT Increased elapsed time is likely due
PROMPT to the sort that is transparently performed to cluster
PROMPT the data as it is inserted into the SALES_AC table.
--
INSERT /*+ APPEND */ INTO sales_ac SELECT * FROM sales_source
/
--
PROMPT Observe the addition of "SORT ORDER BY" in the execution plan
--
SELECT * FROM TABLE(dbms_xplan.display_cursor)
/
COMMIT
/

set timing off

PROMPT Gather table statistics
EXECUTE dbms_stats.gather_table_stats(ownname=>NULL,tabname=>'sales');
EXECUTE dbms_stats.gather_table_stats(ownname=>NULL,tabname=>'sales_ac');









