set trims on pagesize 100 linesize 250 
column table_name format a25
column partition_or_global format a25
column index_name format a25

alter session set NLS_DATE_FORMAT = 'HH24:MI:SS YYYY-MM-DD';

drop table stale_test1 purge;
drop table stale_test2 purge;

create table stale_test1 (col1 number(10));

create table stale_test2 (col1 number(10)) partition by range (col1)
(
 partition p1 values less than (100)
,partition p2 values less than (200));

create index stale_test1_i on stale_test1(col1);
create index stale_test2_i on stale_test2(col1) local;

exec dbms_stats.set_table_prefs(user,'stale_test1','stale_percent','5')
exec dbms_stats.set_table_prefs(user,'stale_test2','stale_percent','5')

insert into stale_test1 values (1);
insert into stale_test2 values (1);
insert into stale_test2 values (100);
commit;

exec dbms_stats.gather_table_stats(user,'stale_test1')
exec dbms_stats.gather_table_stats(user,'stale_test2')

PROMPT All tables and partitions have non-stale stats
PROMPT
select table_name,nvl(partition_name,'GLOBAL') partition_or_global, last_analyzed,stale_stats
from   user_tab_statistics
where  table_name in ('STALE_TEST1','STALE_TEST2')
order  by 1,2;

pause p...

insert into stale_test2 values (1);
commit;

exec dbms_stats.flush_database_monitoring_info
exec dbms_lock.sleep(5)

PROMPT We only need to gather stats for P1 and the global stats for STALE_TEST2
PROMPT
select table_name,nvl(partition_name,'GLOBAL') partition_or_global, last_analyzed,stale_stats
from   user_tab_statistics
where  table_name in ('STALE_TEST1','STALE_TEST2')
order  by 1,2;

pause p...

exec dbms_stats.gather_table_stats(user,'stale_test1')
exec dbms_stats.gather_table_stats(user,'stale_test2')
-- If you want to test on 'gather auto' on 12c, uncomment the two lines below 
-- and comment the two lines above. The results will be similar.
--exec dbms_stats.gather_table_stats(user,'stale_test1',options=>'gather auto')
--exec dbms_stats.gather_table_stats(user,'stale_test2',options=>'gather auto')

PROMPT But gather_table_stats gathers table stats irrespective of staleness
PROMPT so all table and partitions have a new LAST_ANALYZED time
PROMPT
select table_name,nvl(partition_name,'GLOBAL') partition_or_global, last_analyzed,stale_stats
from   user_tab_statistics
where  table_name in ('STALE_TEST1','STALE_TEST2')
order  by 1,2;

PROMPT
PROMPT We used dbms_stats.gather_table_stats
PROMPT 
PROMPT Notice above how all statistics have been re-gathered
PROMPT (compare the LAST_ANALYZED time now and in the previous listing)
PROMPT GATHER_TABLE_STATS does not skip tables if the statistics are not stale.

pause p...

insert into stale_test2 values (1);
insert into stale_test2 values (1);
insert into stale_test2 values (1);
commit;

exec dbms_stats.flush_database_monitoring_info
exec dbms_lock.sleep(5)

PROMPT 
PROMPT We are ready to try again, this time with GATHER_SCHEMA_STATS...
select table_name,nvl(partition_name,'GLOBAL') partition_or_global, last_analyzed,stale_stats
from   user_tab_statistics
where  table_name in ('STALE_TEST1','STALE_TEST2')
order  by 1,2;

pause p...

DECLARE
   filter_lst  DBMS_STATS.OBJECTTAB := DBMS_STATS.OBJECTTAB();
BEGIN
   filter_lst.extend(2);
   filter_lst(1).ownname := user;
   filter_lst(1).objname := 'stale_test1';
   filter_lst(2).ownname := user;
   filter_lst(2).objname := 'stale_test2';
   DBMS_STATS.GATHER_SCHEMA_STATS(ownname=>user,obj_filter_list=>filter_lst,options=>'gather auto');
END;
/

PROMPT
PROMPT We used dbms_stats.gather_schema_stats(obj_filter_list=> ... , options=>'gather auto')
PROMPT 
PROMPT This time non-stale tables and partitions have been skipped
PROMPT and statistics have only been gathered where there are stale stats.
PROMPT Bear in mind that STALE_TEST2 has new statistics at the GLOBAL level 
PROMPT because the stale P1 partition means that the table's global-level 
PROMPT statistics must be updated too.
select table_name,nvl(partition_name,'GLOBAL') partition_or_global, last_analyzed,stale_stats
from   user_tab_statistics
where  table_name in ('STALE_TEST1','STALE_TEST2')
order  by 1,2;

pause p...

PROMPT 
PROMPT The indexes are treated correctly too
PROMPT
select table_name,index_name,nvl(partition_name,'GLOBAL') partition_or_global, last_analyzed,stale_stats
from   user_ind_statistics
where  table_name in ('STALE_TEST1','STALE_TEST2')
order  by 1,3;

