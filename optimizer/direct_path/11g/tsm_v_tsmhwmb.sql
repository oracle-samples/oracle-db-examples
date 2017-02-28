set linesize 260
column PLAN_TABLE_OUTPUT format a200
set pagesize 200
set trims on
set tab off
set echo on
spool tsm_v_tsmhwmb

alter session enable parallel dml;
alter session set parallel_force_local = FALSE;
alter session set parallel_degree_policy = 'MANUAL';

DROP TABLE sales_dl;
DROP TABLE sales_dl_copy;

CREATE TABLE sales_dl (sale_id NUMBER(10), customer_id NUMBER(10));

DECLARE
   i NUMBER(10);
BEGIN
   FOR i IN 1..10
   LOOP
   INSERT INTO sales_dl
      SELECT ROWNUM, MOD(ROWNUM,1000)
      FROM   dual
      CONNECT BY LEVEL <= 100000;
      COMMIT;
   END LOOP;
END;
/

EXEC dbms_stats.gather_table_stats(ownname=>NULL, tabname=>'SALES_DL');

alter session enable parallel dml;
alter session set parallel_force_local = FALSE;
alter session set parallel_degree_policy = 'MANUAL';

CREATE TABLE sales_dl_copy
AS
SELECT * FROM sales_dl WHERE 1=-1;


INSERT  /*+ APPEND PARALLEL(t1,8) */
INTO    sales_dl_copy t1
SELECT  /*+ PARALLEL(t2,8) */ *
FROM    sales_dl t2;

select * from table(dbms_xplan.display_cursor);

commit;

--
-- Here are the exents for the SALES_DL_COPY table
-- It should be similar in 11g and 12c
--
select segment_type,extent_id,bytes,blocks
from user_extents
where segment_name ='SALES_DL_COPY'
order by extent_id;

-- 
-- Perform four more PIDL operations
--
BEGIN
   FOR i IN 1..4
   LOOP
      INSERT /*+ APPEND PARALLEL(t1,8) */ INTO sales_dl_copy t1
      SELECT /*+ PARALLEL(t2,8) */ * FROM  sales_dl t2 WHERE rownum<10000;
      COMMIT;
   END LOOP;
END;
/

--
-- Here are the extents for SALES_DL_COPY after
-- five PIDL operations at DOP 8.
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
--

select segment_type,extent_id,bytes,blocks
from user_extents
where segment_name ='SALES_DL_COPY'
order by extent_id;

spool off
