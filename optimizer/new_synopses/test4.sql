set echo on
set timing  on
set linesize 1000
set pagesize 100
set trims on

--
-- We are going to perform a partition exchange load and 
-- take a look at the timings for Adaptive Sampling synopses.
-- Compare the results here with "test3".
--
exec dbms_stats.set_table_prefs(null,'t1','incremental_staleness', 'NULL')

exec DBMS_STATS.SET_TABLE_PREFS (null,'exch','INCREMENTAL_LEVEL','table');
exec dbms_stats.set_table_prefs(null,'exch', 'approximate_ndv_algorithm', 'adaptive sampling')
exec dbms_stats.delete_table_stats(null,'exch')
exec dbms_stats.gather_table_stats(null,'exch');

--
-- The exchange table has synopses
--
select count(*) from sys.WRI$_OPTSTAT_SYNOPSIS$
where bo# = (select object_id from user_objects where object_name = 'EXCH' and object_type = 'TABLE');

--
-- The exchange table has 5 columns...
--
select count(*) from sys.WRI$_OPTSTAT_SYNOPSIS_HEAD$
where bo# = (select object_id from user_objects where object_name = 'EXCH' and object_type = 'TABLE');

select spare1,spare2 from sys.WRI$_OPTSTAT_SYNOPSIS_HEAD$
where  bo# = (select object_id from user_objects where object_name = 'EXCH' and object_type = 'TABLE')
and rownum<11;

pause

--
-- Get stats up to date on our main table, T1
--
exec dbms_stats.set_table_prefs(null,'t1', 'approximate_ndv_algorithm', 'adaptive sampling')
exec dbms_stats.delete_table_stats(null,'t1')
exec dbms_stats.gather_table_stats(null,'t1')

pause

--
-- Perform the exchange - we expect it to be fast, but not
-- as fast as HyperLogLog because we must manipulate more
-- synopsis data in this case
--
alter table t1 exchange partition p1 with table exch;

pause

--
-- Gather stats to refresh the global-level table stats
-- We expect this to be very fast because the synopsis is used
--
exec dbms_stats.gather_table_stats(null,'t1')

pause

--
-- Confirm we have Adaptive Sampling synopses...
--
@look

pause

--
-- Note these timings for Adaptive Sampling
-- Compare the timings with "test3"
--
alter table t1 exchange partition p1 with table exch;
alter table t1 exchange partition p1 with table exch;
alter table t1 exchange partition p1 with table exch;
alter table t1 exchange partition p1 with table exch;
--
-- This last exchange and gather stats returns the T1 to the state it
-- it was prior to the first exchange.
--
alter table t1 exchange partition p1 with table exch;
exec dbms_stats.gather_table_stats(null,'t1')
