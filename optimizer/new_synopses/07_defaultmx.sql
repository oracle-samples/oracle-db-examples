set echo on
set timing  on
set linesize 1000
set pagesize 100
set trims on
column partition_name format a40
column ndv_alg format a30
column inc_stale format a30

drop table t1 purge;
drop table exch purge;

create table t1 (id number(10),num1 number(10), num2 number(10),txt varchar2(20))
partition by range (num1)
interval (1) (
 partition p1 values less than (1)
,partition p2 values less than (2));

insert /*+ APPEND */ into t1
select rownum, mod(rownum,2), mod(rownum,1000),'X'||mod(rownum,10000)
from   (select 1 from dual connect by level <=1000);

commit;

create table exch as select * from t1 where 1=-1;

insert /*+ APPEND */ into exch
select rownum,0,mod(rownum,10000),'X'||mod(rownum,100000)
from   (select 1 from dual connect by level <=100);

commit;

--
-- Enable incremental statistics
--
exec dbms_stats.set_table_prefs(null,'t1','incremental','true')
exec dbms_stats.set_table_prefs(null,'exch','incremental','true')

--
-- Prepare to create a synopsis on the EXCH table
--
exec DBMS_STATS.SET_TABLE_PREFS (null,'exch','INCREMENTAL_LEVEL','table');
--
-- The exchange table has an old-style synopsis
--
exec dbms_stats.set_table_prefs(null,'exch', 'approximate_ndv_algorithm', 'adaptive sampling')
exec dbms_stats.gather_table_stats(null,'exch');

--
-- The partitioned table has old-style synopses
--
exec dbms_stats.set_table_prefs(null,'t1', 'approximate_ndv_algorithm', 'hyperloglog')
exec dbms_stats.gather_table_stats(null,'t1')

@t1check

pause

alter table t1 exchange partition p1 with table exch;

@t1check

pause

--
-- Add a partition
--
insert /*+ APPEND */ into t1
select rownum, 2, mod(rownum,1000),'X'||mod(rownum,10000)
from   (select 1 from dual connect by level <=1000);

exec dbms_stats.gather_table_stats(null,'t1')

@t1check

pause

--
-- Make P1 stale
--
insert /*+ APPEND */ into t1
select rownum, 0, mod(rownum,1000),'X'||mod(rownum,10000)
from   (select 1 from dual connect by level <=1000);

exec dbms_stats.gather_table_stats(null,'t1')

@t1check
