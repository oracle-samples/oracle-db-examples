set pagesize 1000
set linesize 200
column table_name format a30
column index_name format a30
column owner format a30
column column_name format a30
column tcb_pref format a10
column cuse format a100 wrapped
column analyzed format a19
column extension format a20
break on table_name

prompt =======================================================================
prompt This script displays the various metadata associated with optimizer
prompt statistics and adaptive features.
prompt Specifically:
prompt   Stats informaiton in DBA_TABLES
prompt   Stats information in DBA_INDEXES  
prompt   Extended statistics
prompt   Histograms
prompt   Column usage information
prompt   Table preferences
prompt =======================================================================

prompt Compare analyzed dates between T1 and T2
prompt S1.T1 and S1.T2 have slightly different row counts. The difference will
prompt be apparent in the statistics until the statistics are copied from T1 to T2.
prompt ============================================================================
select table_name,to_char(last_analyzed,'YYYY-MM-DD HH24:MI:SS') analyzed, num_rows
from   dba_tables 
where  owner in ('S1') and table_name in ('T1','T2') order by 1;

select table_name,column_name,num_distinct 
from   dba_tab_col_statistics
where  owner in ('S1') and table_name in ('T1','T2')
order  by 1,2;

prompt Compare analyzed dates between T1 and T2 for indexes
prompt and notice that the index statistics are not copied
prompt because we don't have a remap_index in DP
prompt ====================================================
select table_name,index_name,num_rows,to_char(last_analyzed,'YYYY-MM-DD HH24:MI:SS') analyzed
from   dba_indexes 
where  owner in ('S1') and table_name in ('T1','T2') order by 1;

prompt Extended stats. Compare user S1 with S2...
prompt ==========================================
select table_name,extension
from  dba_stat_extensions
where owner in ('S1')
order by owner,table_name;

prompt Histograms. Compare user S1 with S2...
prompt ======================================
select table_name,column_name,histogram
from  dba_tab_col_statistics
where owner in ('S1')
order by owner,table_name,column_name;

prompt Number of COL_USAGE$ entries for T1
prompt ===================================
select count(*) from sys.col_usage$ 
where obj# = (select object_id from dba_objects where object_name = 'T1' and owner = 'S1');
prompt Number of COL_USAGE$ entries for T2
prompt ===================================
select count(*) from sys.col_usage$ 
where obj# = (select object_id from dba_objects where object_name = 'T2' and owner = 'S1');

set long 1000000
prompt Column usage report for S1.T1
prompt =============================
select dbms_stats.report_col_usage(ownname=>'s1',tabname=>'t1') cuse from dual;
prompt Column usage report for S1.T2
prompt =============================
select dbms_stats.report_col_usage(ownname=>'s1',tabname=>'t2') cuse from dual;

prompt S1.T1 TABLE_CACHED_BLOCKS preference
prompt ====================================
select dbms_stats.get_prefs ('TABLE_CACHED_BLOCKS','s1','t1') tcb_pref from dual;
prompt S1.T2 TABLE_CACHED_BLOCKS preference (should match S1.T1 once copied)
prompt =====================================================================
select dbms_stats.get_prefs ('TABLE_CACHED_BLOCKS','s1','t2') tcb_pref from dual;
