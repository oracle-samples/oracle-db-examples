set trims on pagesize 100 linesize 250 
column table_name format a25
column partition_or_global format a25
column index_name format a25

alter session set NLS_DATE_FORMAT = 'HH24:MI:SS YYYY-MM-DD';

drop table stale_test1 purge;
drop table stale_test2 purge;

create table stale_test1 (col1 number(10));
create table stale_test2 (col1 number(10));

create index stale_test1_i on stale_test1(col1);
create index stale_test2_i on stale_test2(col1);

exec dbms_stats.set_table_prefs(user,'stale_test1','stale_percent','5')
exec dbms_stats.set_table_prefs(user,'stale_test2','stale_percent','5')

insert into stale_test1 values (1);
insert into stale_test2 values (1);
commit;

exec dbms_stats.gather_table_stats(user,'stale_test1')
exec dbms_stats.gather_table_stats(user,'stale_test2')

PROMPT Table stats are not STALE
PROMPT
select table_name, last_analyzed,stale_stats
from   user_tab_statistics
where  table_name in ('STALE_TEST1','STALE_TEST2')
order  by 1,2;

pause p...

exec dbms_lock.sleep(2);
exec dbms_stats.gather_table_stats(user,'stale_test1')
exec dbms_stats.gather_table_stats(user,'stale_test2')

PROMPT But even though the stats were not stale, statistics have been re-gathered
PROMPT You can see this because the LAST_ANALYZED time has changed since we last looked (above)
PROMPT
select table_name,last_analyzed,stale_stats
from   user_tab_statistics
where  table_name in ('STALE_TEST1','STALE_TEST2')
order  by 1,2;

pause p...

PROMPT Make STALE_TEST2 stale
PROMPT 
insert into stale_test2 values (10);
insert into stale_test2 values (10);
commit;

exec dbms_stats.flush_database_monitoring_info


select table_name,last_analyzed,stale_stats
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
   filter_lst(1).ownname := user;
   filter_lst(1).objname := 'stale_test2';
   DBMS_STATS.GATHER_SCHEMA_STATS(ownname=>user,obj_filter_list=>filter_lst,options=>'gather auto');
END;
/

exec dbms_lock.sleep(2);
PROMPT
PROMPT We used dbms_stats.gather_schema_stats(obj_filter_list=> ... , options=>'gather auto')
PROMPT 
PROMPT This time the non-stale table has been skipped
PROMPT and statistics have only been gathered where there are stale stats.
PROMPT You can see if you consider the LAST_ANALYZED time.
select table_name,last_analyzed,stale_stats
from   user_tab_statistics
where  table_name in ('STALE_TEST1','STALE_TEST2')
order  by 1,2;

