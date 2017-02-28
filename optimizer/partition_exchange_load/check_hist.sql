PROMPT ======================================================================================
PROMPT Check histograms for all (sub)partitions
PROMPT ======================================================================================
set serveroutput on
set verify off
set feedback off
set linesize 1000
set trims on
set serveroutput on
column column_name format a40
column table_name format a40
column partition_name format a40
column subpartition_name format a40

accept ptable prompt 'Enter the name of the partitioned table: '

prompt
prompt Table-level histograms:
prompt
select column_name 
from  user_tab_col_statistics
where histogram != 'NONE'
and   table_name = upper('&ptable')
order by column_name;

prompt
prompt Partition columns that have histograms not present at table-level:
prompt
break on partition_name
select partition_name,column_name
from  user_part_col_statistics
where histogram != 'NONE'
and   table_name = upper('&ptable')
and   column_name not in (select column_name
                          from  user_tab_col_statistics
                          where histogram is not null
                          and   histogram != 'NONE'
                          and   table_name = upper('&ptable'))
order by partition_name,column_name;
clear breaks

prompt
prompt Subpartition columns that have histograms not present at table-level: 
prompt
break on subpartition_name
select subpartition_name,column_name
from  user_subpart_col_statistics  
where histogram != 'NONE' 
and   table_name = upper('&ptable')
and   column_name not in (select column_name  
                          from  user_tab_col_statistics
                          where histogram is not null 
                          and   histogram != 'NONE' 
                          and   table_name = upper('&ptable'))
order by subpartition_name,column_name;
clear breaks

prompt
prompt Partition columns missing histograms that exist at table-level:
prompt
break on partition_name
select partition_name, column_name
from  user_part_col_statistics
where histogram = 'NONE'
and   table_name = upper('&ptable')
and   column_name in (select column_name
                      from  user_tab_col_statistics
                      where histogram is not null
                      and   histogram != 'NONE'
                      and   table_name = upper('&ptable'))
order by partition_name,column_name;
clear breaks

prompt
prompt Subpartition columns missing histograms that exist at table-level:
prompt
break on subpartition_name
select subpartition_name, column_name
from  user_subpart_col_statistics
where histogram = 'NONE'
and   table_name = upper('&ptable')
and   column_name in (select column_name
                      from  user_tab_col_statistics
                      where histogram is not null
                      and   histogram != 'NONE'
                      and   table_name = upper('&ptable'))
order by subpartition_name,column_name;
clear breaks
