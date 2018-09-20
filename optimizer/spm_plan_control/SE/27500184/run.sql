set linesize 280
set trims on
set pagesize 200
set tab off
set feedback on
column plan_name format a30
column sql_handle format a30
column sql_text format a50
column plan_table_output format a150

column creator format a10
column origin format a35
column parsing_schema_name format a10
column description format a10
column module format a15
column action format a15
column version format a15
column signature format 9999999999999999999999
show user

set echo on

select /* HELLO */ num from bob where id = 100;
select sql_id from v$sql where sql_text = 'select /* HELLO */ num from bob where id = 100';

select /* HELLO */ num from bob where id = 100;
select * from dba_sql_plan_baselines;
select * from  v$sql_shared_cursor where sql_id = '8c2dqym0cbqvj' order by child_number;

select /* HELLO */ num from bob where id = 100;
select * from dba_sql_plan_baselines;
select * from  v$sql_shared_cursor where sql_id = '8c2dqym0cbqvj' order by child_number;

select /* HELLO */ num from bob where id = 100;
select * from dba_sql_plan_baselines;
select * from  v$sql_shared_cursor where sql_id = '8c2dqym0cbqvj' order by child_number;

select /* HELLO */ num from bob where id = 100;
select * from dba_sql_plan_baselines;
select * from  v$sql_shared_cursor where sql_id = '8c2dqym0cbqvj' order by child_number;

--
-- Put in a host sleep - and try a flush
--
host sleep 10
exec dbms_stats.flush_database_monitoring_info

select /* HELLO */ num from bob where id = 100;
select * from dba_sql_plan_baselines;
select * from  v$sql_shared_cursor where sql_id = '8c2dqym0cbqvj' order by child_number;

pause p...

--
-- Can we get a plan?
-- In SE we can't because the cursor is repeatedly invalidated
--
select /* HELLO */ num from bob where id = 100;
select * from table(dbms_xplan.display_cursor(format=>'TYPICAL'));

show user
