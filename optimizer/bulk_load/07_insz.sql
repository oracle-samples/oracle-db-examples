set timing on
set echo on
set linesize 300
column table_name format a30
column segment_name format a30
column plan_table_output format a150
column partition_name format a30
set pagesize 1000
set trims on
spool 07_insz

--
-- This will ensure that we are not using AutoDOP
-- Auto DOP is not a "problem", but using manual
-- DOP will mean that the script will work
-- as intended in this test case.
--
alter session set parallel_degree_policy = 'MANUAL';
--
-- Enable parallel DML so that the write into the
-- staging table will be in parallel for maximum
-- performance.
--
alter session enable parallel dml;

--
-- Read the data files via the gzip external table
-- and insert the rows into the staging table.
-- We can read the gzip files at DOP 2 because there are
-- two files - we can't read just part of a gzip file so if we
-- want to read at DOP 4, then we will need 4 gzip files.
--
INSERT /*+ APPEND PARALLEL(itab,2) */ INTO sales_stage itab
SELECT /*+ PARALLEL(tab,2) */ *
FROM   salesz_ext tab
/

SELECT *
FROM   table(dbms_xplan.display_cursor);

--
-- Expect to see an error here!
-- This is because you will need to 
-- commit the data before it is read.
--
SELECT count(*)
FROM   sales_stage
/

--
-- Commit the transaction
--
COMMIT;

--
-- Now you can read the loaded data
--
SELECT count(*)
FROM   sales_stage
/

spool off
