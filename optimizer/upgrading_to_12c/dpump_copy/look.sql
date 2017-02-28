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
break on owner

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
prompt   SQL plan directives
prompt =======================================================================

prompt Compare analyzed dates between S1 and S2 for tables
prompt S1.T1 and S2.T2 have slightly different row counts. The difference will
prompt be apparent in the statistics until the statistics are copied from S1 to S2.
prompt ============================================================================
select table_name,owner,to_char(last_analyzed,'YYYY-MM-DD HH24:MI:SS') analyzed, num_rows
from   dba_tables 
where  owner in ('S1','S2');

prompt Compare analyzed dates between S1 and S2 for indexes
prompt ====================================================
select table_name,index_name,owner,to_char(last_analyzed,'YYYY-MM-DD HH24:MI:SS') analyzed
from   dba_indexes 
where  owner in ('S1','S2');

prompt Extended stats. Compare user S1 with S2...
prompt ==========================================
select owner,table_name,extension
from  dba_stat_extensions
where owner in ('S1','S2')
order by owner,table_name;

prompt Histograms. Compare user S1 with S2...
prompt ======================================
select owner,table_name,column_name,histogram
from  dba_tab_col_statistics
where owner in ('S1','S2')
order by owner,table_name,column_name;

prompt Number of COL_USAGE$ entries for S1
prompt ===================================
select count(*) from sys.col_usage$ 
where obj# = (select object_id from dba_objects where object_name = 'T1' and owner = 'S1');
prompt Number of COL_USAGE$ entries for S2
prompt ===================================
select count(*) from sys.col_usage$ 
where obj# = (select object_id from dba_objects where object_name = 'T1' and owner = 'S2');

set long 1000000
prompt Column usage report for S1.T1
prompt =============================
select dbms_stats.report_col_usage(ownname=>'s1',tabname=>'t1') cuse from dual;
prompt Column usage report for S2.T1
prompt =============================
select dbms_stats.report_col_usage(ownname=>'s2',tabname=>'t1') cuse from dual;

prompt S1.T1 TABLE_CACHED_BLOCKS preference
prompt ====================================
select dbms_stats.get_prefs ('TABLE_CACHED_BLOCKS','s1','t1') tcb_pref from dual;
prompt S2.T1 TABLE_CACHED_BLOCKS preference (should match S1.T1 once copied)
prompt =====================================================================
select dbms_stats.get_prefs ('TABLE_CACHED_BLOCKS','s2','t1') tcb_pref from dual;


PROMPT SQL plan directives
PROMPT ===================
exec dbms_spd.flush_sql_plan_directive;

COLUMN dir_id FORMAT A20
COLUMN owner FORMAT A10
COLUMN object_name FORMAT A10
COLUMN col_name FORMAT A10

SELECT o.owner, o.object_name, 
       o.subobject_name col_name, o.object_type, d.type, d.state, d.reason
FROM   dba_sql_plan_directives d, dba_sql_plan_dir_objects o
WHERE  d.directive_id=o.directive_id
AND    o.owner in ('S1','S2')
ORDER BY 1,2,3,4,5;

