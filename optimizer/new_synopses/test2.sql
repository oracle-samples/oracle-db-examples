set echo on
set timing  on
set linesize 1000
set pagesize 100
set trims on

--
-- HyperLogLog synopses
--
exec dbms_stats.set_table_prefs(null,'t1', 'approximate_ndv_algorithm', 'hyperloglog')
exec dbms_stats.delete_table_stats(null,'t1')
exec dbms_stats.gather_table_stats(null,'t1')

pause

--
-- Confirm we have HLL synopses
--
@t1check

pause

--
-- Take a look at synopses for HyperLogLog algorithm
--
--
-- No rows in this table for T1
--
select count(*) from sys.WRI$_OPTSTAT_SYNOPSIS$
where bo# = (select object_id from user_objects where object_name = 'T1' and object_type = 'TABLE');

--
-- Number of rows = #Partitions * #Table Columns
--
select count(*) from sys.WRI$_OPTSTAT_SYNOPSIS_HEAD$
where bo# = (select object_id from user_objects where object_name = 'T1' and object_type = 'TABLE');

--
-- Binary NDV data for each column per partition
-- Just showing the first few rows...
--
select spare1,spare2 from sys.WRI$_OPTSTAT_SYNOPSIS_HEAD$
where  bo# = (select object_id from user_objects where object_name = 'T1' and object_type = 'TABLE')
and rownum<11;

pause

--
-- Adaptive sampling (pre-Oracle Database 12c Release 2)
--
exec dbms_stats.set_table_prefs(null,'t1', 'approximate_ndv_algorithm', 'adaptive sampling')
exec dbms_stats.delete_table_stats(null,'t1')
exec dbms_stats.gather_table_stats(null,'t1')

--
-- Confirm we have Adaptive Sampling synopses
--
@t1check

pause

--
-- NDV data for Adaptive Sampling algorythm
-- The number of rows is related to #Partitions, #Columns and NDV per column
--
select count(*) from sys.WRI$_OPTSTAT_SYNOPSIS$
where bo# = (select object_id from user_objects where object_name = 'T1' and object_type = 'TABLE');

--
-- Same #rows as HyperLogLog
--
select count(*) from sys.WRI$_OPTSTAT_SYNOPSIS_HEAD$
where bo# = (select object_id from user_objects where object_name = 'T1' and object_type = 'TABLE');

--
-- No binary NDV data
--
select spare1 ,spare2 from sys.WRI$_OPTSTAT_SYNOPSIS_HEAD$
where  bo# = (select object_id from user_objects where object_name = 'T1' and object_type = 'TABLE')
and rownum<11;

pause

-- Ignore this timing
exec dbms_stats.delete_table_stats(null,'t1')

--
-- Look at the timings for deleting and gathering statistics
-- Adaptive Sampling
--
exec dbms_stats.set_table_prefs(null,'t1', 'approximate_ndv_algorithm', 'adaptive sampling')
exec dbms_stats.gather_table_stats(null,'t1')

exec dbms_stats.set_table_prefs(null,'t1', 'approximate_ndv_algorithm', 'adaptive sampling')
exec dbms_stats.delete_table_stats(null,'t1')
exec dbms_stats.gather_table_stats(null,'t1')

exec dbms_stats.set_table_prefs(null,'t1', 'approximate_ndv_algorithm', 'adaptive sampling')
exec dbms_stats.delete_table_stats(null,'t1')
exec dbms_stats.gather_table_stats(null,'t1')

exec dbms_stats.set_table_prefs(null,'t1', 'approximate_ndv_algorithm', 'adaptive sampling')
exec dbms_stats.delete_table_stats(null,'t1')
exec dbms_stats.gather_table_stats(null,'t1')

-- Ignore this timing
exec dbms_stats.delete_table_stats(null,'t1')

--
-- Compare these timing with the previous timings for deleting and gathering statistics
-- HyperLogLog
--
exec dbms_stats.set_table_prefs(null,'t1', 'approximate_ndv_algorithm', 'hyperloglog')
exec dbms_stats.gather_table_stats(null,'t1')

exec dbms_stats.set_table_prefs(null,'t1', 'approximate_ndv_algorithm', 'hyperloglog')
exec dbms_stats.delete_table_stats(null,'t1')
exec dbms_stats.gather_table_stats(null,'t1')

exec dbms_stats.set_table_prefs(null,'t1', 'approximate_ndv_algorithm', 'hyperloglog')
exec dbms_stats.delete_table_stats(null,'t1')
exec dbms_stats.gather_table_stats(null,'t1')

exec dbms_stats.set_table_prefs(null,'t1', 'approximate_ndv_algorithm', 'hyperloglog')
exec dbms_stats.delete_table_stats(null,'t1')
exec dbms_stats.gather_table_stats(null,'t1')

