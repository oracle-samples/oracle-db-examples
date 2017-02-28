-- ===================================================================================
-- Complete example of a partition exchange load using incremental stats
-- and a subpartitioned main table.
-- ===================================================================================
set linesize 2000
set trims on
set pagesize 50
set echo on

drop table range_list_main_tab;
drop table list_part_load_tab;

--
-- interval range-list table
--
create table range_list_main_tab
        (num number,
         ten number)
partition by range (num)
interval (1000)
subpartition by list (ten)
subpartition template
        (subpartition t_spart1 values (0,2,4,6,8),
         subpartition t_spart2 values (1,3,5,7,9))
        (partition range_list_main_part1 values less than (1000),
         partition range_list_main_part2 values less than (2000));

create index range_list_main_tab_n on range_list_main_tab(num) local;

--
-- list partitioned table
--
create table list_part_load_tab
        (num number,
         ten number)
partition by list (ten)
        (partition list_part_load_part1 values (0,2,4,6,8),
         partition list_part_load_part2 values  (1,3,5,7,9));

exec dbms_stats.set_table_prefs(null, 'range_list_main_tab', 'incremental', 'true');
exec dbms_stats.set_table_prefs(null, 'list_part_load_tab', 'incremental', 'true');
exec dbms_stats.set_table_prefs(null, 'range_list_main_tab', 'incremental_level', 'partition');
exec dbms_stats.set_table_prefs(null, 'list_part_load_tab', 'incremental_level', 'table');

--
-- The main table will have 998 rows
--
insert into range_list_main_tab
        select rownum,mod(rownum,10)
        from   dual
        connect by level<500
        union all
        select rownum+1000,mod(rownum,10)
        from   dual
        connect by level<500;

--
-- The load table will have 999 rows
--
insert into list_part_load_tab
        select rownum,mod(rownum,10)
        from   dual
        connect by level<1000;

exec dbms_stats.gather_table_stats(null, 'range_list_main_tab');

--
-- Let's sleep here to give the main table and load table
-- different last_analyzed times
--
host sleep 5

exec dbms_stats.gather_table_stats(null, 'list_part_load_tab');

--
-- Should be 1000 rows
--
select count(*) from range_list_main_tab;

select to_char(last_analyzed,'dd-mon-yyyy hh24:mi:ss') table_ana
from   user_tables
where  table_name = upper('range_list_main_tab');

select partition_name, to_char(last_analyzed,'dd-mon-yyyy hh24:mi:ss') part_ana
from   user_tab_partitions
where  table_name = upper('range_list_main_tab')
order by partition_position;

select subpartition_name, to_char(last_analyzed,'dd-mon-yyyy hh24:mi:ss') subpart_ana
from   user_tab_subpartitions
where  table_name = upper('range_list_main_tab')
order by subpartition_name;

select to_char(last_analyzed,'dd-mon-yyyy hh24:mi:ss') load_table_ana
from   user_tables
where  table_name = upper('list_part_load_tab');

select partition_name, to_char(last_analyzed,'dd-mon-yyyy hh24:mi:ss') load_part_ana
from   user_tab_partitions
where  table_name = upper('list_part_load_tab')
order by partition_position;


--
-- Perform the exchange after a delay
--
host sleep 5
alter table range_list_main_tab
        exchange partition range_list_main_part1
        with table list_part_load_tab;

--
-- Exchange complete at:
--
select to_char(sysdate,'dd-mon-yyyy hh24:mi:ss') exchange_complete
from dual;

exec dbms_stats.gather_table_stats(null, 'range_list_main_tab');

--
-- Should now be 1498 rows
--
select count(*) from range_list_main_tab;

--
-- The time shown here will be the most recent because the global
-- statistics must be updated after the partition has been exchanged.
-- So, expect the time to be similar to the completion exchange time.
--
select to_char(last_analyzed,'dd-mon-yyyy hh24:mi:ss') table_ana
from   user_tables
where  table_name = upper('range_list_main_tab');

--
-- Part 1 statistics were gathered earlier, because they came from the load
-- table. They did not have to be regathered after the partition was echanged.
-- Part 2 statistics have not been regathered - there is no need.
--
select partition_name, to_char(last_analyzed,'dd-mon-yyyy hh24:mi:ss') part_ana
from   user_tab_partitions
where  table_name = upper('range_list_main_tab')
order by partition_position;

--
-- The Part 1 subpartition stats came from the load table so they have not
-- been regathered after the exchange.
-- Part 2 subpartition stats have not been regathered - there is no need.
--
select subpartition_name, to_char(last_analyzed,'dd-mon-yyyy hh24:mi:ss') subpart_ana
from   user_tab_subpartitions
where  table_name = upper('range_list_main_tab')
order by subpartition_name;

