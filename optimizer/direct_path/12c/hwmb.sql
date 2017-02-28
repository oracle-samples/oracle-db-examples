set linesize 260
column PLAN_TABLE_OUTPUT format a200
set pagesize 200
set trims on
set tab off
set echo on
spool hwmb

DROP TABLE sales_dl;

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

alter table sales_dl parallel 4;

alter session set parallel_force_local = FALSE;
alter session set parallel_degree_policy = 'MANUAL';
alter session enable parallel dml;
alter session enable parallel ddl;

drop table sales_p1;
drop table sales_p2;

--
-- TSM/HWMB PCTAS
--
create table sales_p1 partition by hash (sale_id) partitions 4 
parallel 4
as select * from sales_dl
/

select * from table(dbms_xplan.display_cursor);

create table sales_p2 partition by hash (sale_id) partitions 4 
parallel 4
as select * from sales_dl where 1=-1
/

--
-- An HWMB PIDL 
--
insert /*+ append */
into sales_p2 t1
select * from sales_p1 t2;

select * from table(dbms_xplan.display_cursor);

commit;

