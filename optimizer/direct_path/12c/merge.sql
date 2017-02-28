set linesize 260
column PLAN_TABLE_OUTPUT format a200
set pagesize 200
set trims on
set tab off
set echo on
spool merge

alter session enable parallel dml;
alter session set parallel_force_local = FALSE;
alter session set parallel_degree_policy = 'MANUAL';

DROP TABLE sales_dl;
DROP TABLE sales_dl_copy;

CREATE TABLE sales_dl (sale_id NUMBER(10), customer_id NUMBER(10), counter NUMBER(10));

BEGIN
  INSERT INTO sales_dl
     SELECT ROWNUM, MOD(ROWNUM,1000),ROWNUM*2 
     FROM   dual
     CONNECT BY LEVEL <= 1000000;
     COMMIT;
END;
/

EXEC dbms_stats.gather_table_stats(ownname=>NULL, tabname=>'SALES_DL');

alter session enable parallel dml;
alter session set parallel_force_local = FALSE;
alter session set parallel_degree_policy = 'MANUAL';

CREATE TABLE sales_dl_copy
AS
SELECT * FROM sales_dl;

EXEC dbms_stats.gather_table_stats(ownname=>NULL, tabname=>'SALES_DL_COPY');

alter table sales_dl parallel 4;
alter table sales_dl_copy parallel 4;

select segment_type,extent_id,bytes,blocks
from user_extents
where segment_name ='SALES_DL_COPY'
order by extent_id;

MERGE INTO sales_dl_copy sdlc USING (
SELECT sale_id, customer_id  
FROM  sales_dl WHERE sale_id < 10000
) sdl
ON (sdlc.sale_id = sdl.sale_id - 5000)
WHEN MATCHED THEN 
         UPDATE SET sdlc.counter = - sdlc.counter 
WHEN NOT MATCHED THEN
         INSERT /*+ APPEND */ (sale_id,customer_id) 
         VALUES (sdl.sale_id-5000,sdl.customer_id)
;

select * from table(dbms_xplan.display_cursor);

commit;

--
-- Here are the extents for SALES_DL_COPY after
-- the MERGE operation
-- Compare the 11g and 12c case.
--
-- Your exact results will depend on:
--   DB block size (8K in my case)
--   Tablespace storage defaults (I am using default USERS tablespace)
--
-- The number of extents in the 12c case will
-- also depend on the number of active RAC instances.
-- In my case it is two.
--
-- Expect fewer extents in the 12c case than the 11g case.
--

select segment_type,extent_id,bytes,blocks
from user_extents
where segment_name ='SALES_DL_COPY'
order by extent_id;

