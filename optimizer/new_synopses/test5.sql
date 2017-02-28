set echo on
set timing  on
set linesize 1000
set pagesize 100
set trims on

--
-- You might think that setting incremental_staleness will
-- prevent us exchanging and adaptive sampling synopsis table
-- with a hyperloglog partition but this is not the case.
-- The incremental_staleness preference is a directive for 
-- statistics gathering; it does not prevent an exchange like this.
--
exec dbms_stats.set_table_prefs(null,'t1','incremental_staleness', NULL)

exec DBMS_STATS.SET_TABLE_PREFS (null,'exch','INCREMENTAL_LEVEL','table');
--
-- The exchange table has an old-style synopsis
--
exec dbms_stats.set_table_prefs(null,'exch', 'approximate_ndv_algorithm', 'adaptive sampling')
exec dbms_stats.delete_table_stats(null,'exch')
exec dbms_stats.gather_table_stats(null,'exch');

--
-- The partitioned table has new-style synopses
--
exec dbms_stats.set_table_prefs(null,'t1', 'approximate_ndv_algorithm', 'hyperloglog')
exec dbms_stats.delete_table_stats(null,'t1')
exec dbms_stats.gather_table_stats(null,'t1')

pause

alter table t1 exchange partition p1 with table exch;

select spare1,spare2 from sys.WRI$_OPTSTAT_SYNOPSIS_HEAD$
where  bo# = (select object_id from user_objects where object_name = 'EXCH' and object_type = 'TABLE')
and rownum<11;

select spare1,spare2 from sys.WRI$_OPTSTAT_SYNOPSIS_HEAD$
where  bo# = (select object_id from user_objects where object_name = 'T1' and object_type = 'TABLE')
and rownum<11;

pause

alter table t1 exchange partition p1 with table exch;

select spare1,spare2 from sys.WRI$_OPTSTAT_SYNOPSIS_HEAD$
where  bo# = (select object_id from user_objects where object_name = 'EXCH' and object_type = 'TABLE')
and rownum<11;

select spare1,spare2 from sys.WRI$_OPTSTAT_SYNOPSIS_HEAD$
where  bo# = (select object_id from user_objects where object_name = 'T1' and object_type = 'TABLE')
and rownum<11;

