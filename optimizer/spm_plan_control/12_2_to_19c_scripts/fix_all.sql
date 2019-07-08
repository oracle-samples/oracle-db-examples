set pagesize 100 linesize 200 trims on tab off feedback off echo off verify off
set serveroutput on
column plan_table_output format a150
column source format a7
column sqlset_name format a40
REM
REM $Header: 
REM
REM Copyright (c) 2019, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   nigel.bayliss@oracle.com
REM
REM SCRIPT
REM   fix_all.sql
REM
REM DESCRIPTION
REM   This script generates a SQL plan baselines by taking a 
REM   known plan from the cursor cache, SQL tuning sets or AWR 
REM   and applies it to an existing SQL statement.
REM
REM   Setting the FIX parameter will create a FIXED SQL plan
REM   baseline. However, it is often beneficial to avoid fixing
REM   the plan baseline and allow SQL plan management to 
REM   find alternative execution plans. Ultimately, these plans 
REM   can be verified and accepted using  SQLplan management 
REM   evolution (because, over time a new plan may be required
REM   to maintain optimimal performance).
REM
REM   If you would like to accept plans manually (rather than
REM   automatically), then you can use the following setting:
REM
REM   BEGIN
REM      DBMS_SPM.SET_EVOLVE_TASK_PARAMETER(
REM          task_name => 'SYS_AUTO_SPM_EVOLVE_TASK', 
REM          parameter => 'ACCEPT_PLANS', 
REM          value => 'false' );
REM   END;
REM   /
REM
REM   In this way, you chosen plans will remain unchanged unless
REM   you manually accept new SQL plan baseline plans.
REM
REM
REM PRE-REQUISITES
REM   1. Oracle Tuning Pack license.
REM
REM PARAMETERS
REM   1. SQL_ID (required)
REM   2. FIX -  A FIXED SQL plan basline is created
REM             The new plan baseline is not FIXED
REM   3. NOFORCE - An exception is raised if a SQL plan
REM                baseline already exists.
REM      FORCE   - Existing SQL plan baselines are disabled (or
REM                dropped in the case of Standard Edition)
REM
REM
REM EXECUTION
REM   1. Connect into SQL*Plus as SYSDBA or user with access to
REM      data dictionary.
REM   2. Execute script fix_awr_spm.sql
REM
REM EXAMPLE
REM   # sqlplus system
REM   SQL> START fix_all.sql [SQL_ID] FIX/NOFIX FORCE/NOFORCE
REM   SQL> START fix_all.sql 8c2dqym0cbqvj fix force
REM

PRO
PRO Parameter 1:
PRO TARGET_SQL_ID (required)
PRO
DEF target_sql_id = '&1';

PRO
PRO Parameter 2:
PRO FIX (required)
PRO
DEF fix = '&2';

PRO
PRO Parameter 3:
PRO FORCE (required)
PRO
DEF force = '&3';

WITH
p AS (
SELECT plan_hash_value,'CACHE' source
  FROM v$sql_plan
 WHERE sql_id = TRIM('&&target_sql_id.')
   AND other_xml IS NOT NULL
 UNION
SELECT plan_hash_value,'AWR' source
  FROM dba_hist_sql_plan
 WHERE sql_id = TRIM('&&target_sql_id.')
   AND other_xml IS NOT NULL ),
m AS (
SELECT plan_hash_value,
       SUM(elapsed_time)/SUM(executions) avg_et_secs
  FROM v$sql
 WHERE sql_id = TRIM('&&target_sql_id.')
   AND executions > 0
 GROUP BY
       plan_hash_value ),
a AS (
SELECT plan_hash_value,
       SUM(elapsed_time_total)/SUM(executions_total) avg_et_secs
  FROM dba_hist_sqlstat
 WHERE sql_id = TRIM('&&target_sql_id.')
   AND executions_total > 0
 GROUP BY
       plan_hash_value )
SELECT p.plan_hash_value,
       p.source,
       ROUND(NVL(m.avg_et_secs, a.avg_et_secs)/1e6, 3) avg_et_secs
  FROM p, m, a
 WHERE p.plan_hash_value = m.plan_hash_value(+)
   AND p.plan_hash_value = a.plan_hash_value(+)
 ORDER BY
       avg_et_secs NULLS LAST;

select plan_hash_value,'SQLSET' source,avg(ROUND(decode(executions,0,0,elapsed_time/executions)/1e6, 3)) avg_et_secs
from   dba_sqlset_statements
where  sql_id = '&&target_sql_id.'
group by plan_hash_value, 'SQLSET' order by plan_hash_value;

prompt
accept source_phv number prompt 'Enter the plan hash value you want to capture: '

declare
   v_np                  pls_integer;
   v_dummy               pls_integer;
   v_sqlsetname          varchar2(40);
   v_sqlsetowner         varchar2(100);
   v_fix_yn              varchar2(3)  := 'NO';
   v_planname            varchar2(100);
   v_newhandle           varchar2(100);
   v_thesource           varchar2(10);
   v_plantime            date;
   v_thesnap             number(30);
   v_signature           number(30);
   v_txt                 clob;
   v_target_sqlid        varchar2(50) := trim('&&target_sql_id.');
   v_source_phv          number(20)   := '&&source_phv.';
   v_fix                 varchar2(100):= upper('&&fix.');
   v_force               varchar2(100):= upper('&&force.');

   cursor get_source is
      select * from (
      SELECT 'CACHE' source,1,null name,null own
      FROM  v$sql_plan
      WHERE sql_id = v_target_sqlid
      AND   plan_hash_value = v_source_phv
      AND   other_xml IS NOT NULL
      UNION
      SELECT 'AWR' source,2,null name,null own
      FROM   dba_hist_sql_plan
      WHERE  sql_id = v_target_sqlid
      AND    plan_hash_value = v_source_phv
      AND    other_xml IS NOT NULL
      UNION
      select 'SQLSET' source,3,sqlset_name name,sqlset_owner
      from   dba_sqlset_statements
      where  sql_id = v_target_sqlid
      and    plan_hash_value = v_source_phv)
      order by 2;

   cursor existing_spbs is
      select sql_handle,plan_name
      from   dba_sql_plan_baselines b,
             v$sqlarea              s
      where  s.exact_matching_signature = b.signature
      and    s.sql_id                   = v_target_sqlid
      and    enabled = 'YES';

   cursor get_handle_and_name is
      select sql_handle,plan_name
      from   dba_sql_plan_baselines b
      where  b.signature = v_signature
      and    b.accepted = 'YES'
      and    rownum = 1;

   cursor spb_plans is
      select t.plan_table_output pout,pb.sql_handle
      from   (select distinct sql_handle from dba_sql_plan_baselines where signature = v_signature) pb,
             table(dbms_xplan.display_sql_plan_baseline(pb.sql_handle,null,'BASIC')) t
      where t.plan_table_output like 'Plan name%'
      or    t.plan_table_output like 'Plan hash%'
      or    t.plan_table_output like 'Enabled%';

   cursor get_max_time is
      select max(timestamp) maxts
      from   dba_hist_sql_plan
      where  sql_id = v_target_sqlid
      and    plan_hash_value = v_source_phv;

   cursor get_snapshot is
      select snap_id
      from   dba_hist_snapshot 
      where  v_plantime between begin_interval_time and end_interval_time;

   cursor get_signature is
      select dbms_sqltune.sqltext_to_signature(sql_text) 
      from (
      select sql_fulltext sql_text
      from   v$sqlarea
      where  sql_id = v_target_sqlid
      and    rownum = 1
      union all
      select sql_text
      from   dba_hist_sqltext
      where  sql_id = v_target_sqlid
      and    rownum = 1
      union all
      select sql_text 
      from   dba_sqlset_statements
      where  sql_id = v_target_sqlid
      and    rownum = 1)
      where rownum = 1;

begin
--
-- Parameters
--
   if (v_fix != 'FIX' and v_fix != 'NOFIX')
   then
      raise_application_error (-20003, 'Parameter number 2 must be FIX or NOFIX'); 
   end if;

   if (v_fix = 'FIX')
   then
      v_fix_yn := 'YES';
   end if;

   if (v_force != 'FORCE' and v_force != 'NOFORCE')
   then
      raise_application_error (-20004, 'Parameter number 3 must be FORCE or NOFORCE');
   end if;
--
-- Find the SQL_ID/PHV we want
--
   open get_source;
   fetch get_source into v_thesource,v_dummy,v_sqlsetname,v_sqlsetowner;
   if (get_source%NOTFOUND)
   then
      close get_source;
      raise_application_error (-20001, 'Cannot find SQL_ID/PHV specified');
   end if;
   close get_source;
--
-- Disable exising SQL plan baselines if FORCE
--
   dbms_output.put_line('...');
   dbms_output.put_line('...Disable existing SQL Plan Baslines for target SQL statement ID: '||v_target_sqlid);
   for rec in existing_spbs
   loop
      if (v_force != 'FORCE')
      then
         raise_application_error (-20005, 'NOFORCE specified and there are existing SQL plan baselines for target SQL statement. Plan baseline name: '||rec.plan_name);
      end if;
      dbms_output.put_line('...... Disable SPB '||rec.sql_handle||' '||rec.plan_name);
      v_np := dbms_spm.alter_sql_plan_baseline(rec.sql_handle,rec.plan_name,'enabled','NO');
   end loop;
--
-- Load the SPB plan based on source
--
   if (v_thesource = 'AWR')
   then
--
--    **
--    ** This is not elegant - but I need to get begin and end SnapID
--    **
--
      open get_max_time;
      fetch get_max_time into v_plantime;
      close get_max_time;
      open get_snapshot;
      fetch get_snapshot into v_thesnap;
      close get_snapshot;
      dbms_output.put_line('... Load from AWR: SnapID '||v_thesnap||' FIXED = '||v_fix_yn);
      v_np := dbms_spm.load_plans_from_awr(fixed=>v_fix_yn,begin_snap=>v_thesnap-1,end_snap=>v_thesnap,
              basic_filter=>'plan_hash_value='''||v_source_phv||''' and sql_id='''||v_target_sqlid||'''');
   end if;

   if (v_thesource = 'CACHE')
   then
      dbms_output.put_line('... Load from cursor cache FIXED = '||v_fix_yn);
      v_np := dbms_spm.load_plans_from_cursor_cache(fixed=>v_fix_yn,sql_id=>v_target_sqlid,plan_hash_value=>v_source_phv);
   end if;

   if (v_thesource = 'SQLSET')
   then
      dbms_output.put_line('... Load from SQL Tuning set '''||v_sqlsetname||''' FIXED = '||v_fix_yn);
      v_np := dbms_spm.load_plans_from_sqlset(fixed=>v_fix_yn,sqlset_name=>v_sqlsetname,sqlset_owner=>v_sqlsetowner,
               basic_filter=>'plan_hash_value='''||v_source_phv||''' and sql_id='''||v_target_sqlid||'''');
   end if;
   dbms_output.put_line('... SQL plan baselines for target SQL statement:');
--
-- Get data on SPBs
-- **
-- ** It seems hard to discover relevant signature, plan name and handle **
-- ** This is not elegant
-- **
--
   open get_signature;
   fetch get_signature into v_signature; 
   close get_signature;

   open get_handle_and_name;
   fetch get_handle_and_name into v_newhandle,v_planname;
   close get_handle_and_name;
--
-- Display information on SPB
--   
   for rec in spb_plans
   loop
      dbms_output.put_line('...... '||rec.pout);
   end loop;

   dbms_output.put_line('--'); 
   dbms_output.put_line('-- To export SQL plan baselines, first create a staging table...'); 
   dbms_output.put_line('-- '); 
   dbms_output.put_line('exec dbms_spm.create_stgtab_baseline(''spm_staging_table'')'); 
   dbms_output.put_line('-- '); 
   dbms_output.put_line('-- To pack the accepted SQL plan baseline...'); 
   dbms_output.put_line('-- '); 
   dbms_output.put_line('declare n pls_integer; begin n := dbms_spm.pack_stgtab_baseline(table_name=>''spm_staging_table'',plan_name=>'''||v_planname||'''); end;'); 
   dbms_output.put_line('/');
   dbms_output.put_line('--'); 
   dbms_output.put_line('--To pack all plan baselines for target SQL statement...'); 
   dbms_output.put_line('-- '); 
   dbms_output.put_line('declare n pls_integer; begin n := dbms_spm.pack_stgtab_baseline(table_name=>''spm_staging_table'',sql_handle=>'''||v_newhandle||'''); end;'); 
   dbms_output.put_line('/');
end;
/
