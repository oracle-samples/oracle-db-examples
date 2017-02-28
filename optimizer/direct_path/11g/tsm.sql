set linesize 200
column PLAN_TABLE_OUTPUT format a130
set pagesize 200
set trims on
set tab off
set echo on
spool tsm

DROP TABLE sales_dl;
DROP TABLE sales_copy;

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

create table sales_copy as select * from sales_dl where 1=-1;

alter session set tracefile_identifier = 'TSM';
ALTER SESSION SET EVENTS='10053 trace name context forever, level 1';

insert /*+ APPEND PARALLEL(t1,8) */ into sales_copy t1
select  /*+ PARALLEL(t2,8) */ * from sales_dl t2;

ALTER SESSION SET EVENTS '10053 trace name context off';

commit;
