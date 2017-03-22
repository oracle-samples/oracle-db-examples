--
-- Create some test tables
-- NOTE!
-- Tables called T1 and EXCH will be dropped
--
set echo on
set timing  on
set linesize 1000
set pagesize 100
set trims on
column partition_name format a40
column ndv_alg format a30
column inc_stale format a30

drop table t1 purge;

create table t1 (id number(10),num1 number(10), num2 number(10),txt varchar2(20))
partition by range (num1) 
interval (1) (
 partition p1 values less than (1)
,partition p2 values less than (2));

insert /*+ APPEND */ into t1
select rownum, mod(rownum,5), mod(rownum,1000),'X'||mod(rownum,10000)
from   (select 1 from dual connect by level <=1000);

commit;

--
-- Enable incremental statistics
--
exec dbms_stats.set_table_prefs(null,'t1','incremental','true')
--
-- Disalow mixed format
--
exec dbms_stats.set_table_prefs(null,'t1', 'incremental_staleness', 'NULL')

--
-- Create old-style synopses
--
exec dbms_stats.set_table_prefs(null,'t1', 'approximate_ndv_algorithm', 'adaptive sampling')
exec dbms_stats.gather_table_stats(null,'t1')

select dbms_stats.get_prefs('approximate_ndv_algorithm',user,'t1') ndv_alg from dual;
select dbms_stats.get_prefs('incremental_staleness',user,'t1') inc_stale from dual;

@t1check

--
-- Add a new partition and don't make any others stale
--
insert /*+ APPEND */ into t1
select rownum, 5, mod(rownum,1000),'X'||mod(rownum,10000)
from   (select 1 from dual connect by level <=1000);

@t1check

exec dbms_stats.set_table_prefs(null,'t1', 'approximate_ndv_algorithm', 'hyperloglog')
select dbms_stats.get_prefs('approximate_ndv_algorithm',user,'t1') ndv_alg from dual;
select dbms_stats.get_prefs('incremental_staleness',user,'t1') inc_stale from dual;
exec dbms_stats.gather_table_stats(null,'t1')

@t1check
