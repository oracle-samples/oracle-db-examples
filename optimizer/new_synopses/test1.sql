--
-- Create some test tables
-- WARNING! Use a test system...
-- Tables called T1 and EXCH will be dropped
--
set echo on
set timing  on
set linesize 1000
set pagesize 100
set trims on

drop table t1 purge;

--
-- This is our main application table
--
create table t1 (id number(10),num1 number(10), num2 number(10),txt1 varchar2(20), txt2 varchar2(20))
partition by range (num1) 
interval (1) (
 partition p1 values less than (1)
,partition p2 values less than (2));

--
-- The the interval-partitioned table will have a large number of partitions
-- once the INSERT has completed. Tables with a large number of partitions
-- have more synopsis data (especially for adaptive sampling), so 
-- differences in the resource cost of managing the two synopsis formats 
-- is easier to see.
--
insert /*+ APPEND */ into t1
select rownum, mod(rownum,512), mod(rownum,1000),'X'||mod(rownum,10000),'Y'||mod(rownum,5)
from   (select 1 from dual connect by level <=3000),
       (select 1 from dual connect by level <=3000);

commit;

drop table exch purge;

--
-- This is a table we can use for partition exchange load
--
create table exch as select * from t1 where 1=-1;

insert /*+ APPEND */ into exch
select rownum,0,mod(rownum,10000),'X'||mod(rownum,100000),'Y'||mod(rownum,5)
from   (select 1 from dual connect by level <=1000),
       (select 1 from dual connect by level <=1000);

commit;

--
-- Enable incremental statistics
--
exec dbms_stats.set_table_prefs(null,'t1','incremental','true')
exec dbms_stats.set_table_prefs(null,'exch','incremental','true')
