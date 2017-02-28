PROMPT ======================================================================================
PROMPT List extended statistics and histograms for a partitioned table
PROMPT ======================================================================================
set serveroutput on
set verify off
set feedback off
set linesize 1000
set pagesize 1000
set trims on
set serveroutput on
column column_name format a40
column extension format a100


accept ptable prompt 'Enter the name of the partitioned table: '

prompt Extended statistics on table...
select extension,
       creator  created_by
from   user_stat_extensions
where  table_name = upper('&ptable');

prompt Histograms at table level...
select column_name
from  user_tab_col_statistics
where histogram != 'NONE'
and   table_name = upper('&ptable');

prompt All columns with histograms at partition level...
select distinct column_name
from   user_part_col_statistics
where  histogram != 'NONE'
and    table_name = upper('&ptable');

prompt All columns with histograms at subpartition level...
select distinct column_name
from   user_subpart_col_statistics
where  histogram != 'NONE'
and    table_name = upper('&ptable');
