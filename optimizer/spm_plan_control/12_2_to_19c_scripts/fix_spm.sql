set pagesize 100 linesize 200 trims on tab off feedback off echo off verify off
set serveroutput on
column plan_table_output format a150
REM
REM $Header: 
REM
REM Copyright (c) 2019, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   nigel.bayliss@oracle.com
REM
REM SCRIPT
REM   fix_spm.sql
REM
REM DESCRIPTION
REM   This script generates a SQL plan baselines by taking a 
REM   known plan from the cursor cache and applies it
REM   to an existing SQL statement.
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
REM   Use case:
REM   
REM   You have a query but the plan is poor. For example:
REM      select num from tab where id = 100;    [Query #1]
REM 
REM   You know this hinted query will give you the plan you want:
REM      select /*+ INDEX(tab tab_idx) num */ from tab where id = 100;    [Query #2]
REM   
REM   Apply the good (Query #2) plan to Query #1 using
REM   a SQL plan baseline, as follows:
REM
REM   SQL> @@fix_spm.sql SQLID_Q#1 SQLID_Q#2 PHV_Q#2 NOFIX FORCE
REM
REM
REM PRE-REQUISITES
REM   1. Oracle Enterprise Edition or
REM   2. Oracle Standard Edition 18c onwards
REM
REM PARAMETERS
REM   1. TARGET_SQL_ID for the statement you need to fix a plan
REM   2. SOURCE_SQL_ID for the statement you want to take the plan from
REM   3. PLAN_HASH_VALUE for the statement you want to take the plan from
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
REM   2. Execute script fix_spm.sql
REM
REM EXAMPLE
REM   # sqlplus system
REM   SQL> START fix_spm.sql [TARGET_SQLID] [SOURCE_SQLID] [SOURCE_PHV] FIX/NOFIX FORCE/NOFORCE
REM   SQL> START fix_spm.sql 8c2dqym0cbqvj  5vh2zbrqwz3nf 4251244305 fix force
REM
REM

PRO
PRO Parameter 1:
PRO TARGET_SQL_ID (required)
PRO
DEF target_sql_id = '&1';

PRO
PRO Parameter 2:
PRO SOURCE_SQL_ID (required)
PRO
DEF source_sql_id = '&2';

PRO
PRO Parameter 3:
PRO SOURCE_PLAN_HASH_VALUE (required)
PRO
DEF source_phv = '&3';

PRO
PRO Parameter 4:
PRO FIX (required)
PRO
DEF fix = '&4';

PRO
PRO Parameter 5:
PRO FORCE (required)
PRO
DEF force = '&5';

PROMPT
PROMPT Source plan...
PROMPT 
select * from table(DBMS_XPLAN.DISPLAY_CURSOR(format=>'basic',sql_id=>'&&source_sql_id.'));

declare
   v_std_edition           varchar2(3);
   v_supported_std_ed      varchar2(3);
   v_found_sqlids          number(2) := 0;
   v_np                    pls_integer;
   v_fix_yn                varchar2(3)  := 'NO';
   v_planname              varchar2(100);
   v_newhandle             varchar2(100);
   v_source_sqlid          varchar2(50) := trim('&&source_sql_id.');
   v_target_sqlid          varchar2(50) := trim('&&target_sql_id.');
   v_source_phv            number(20)   := '&&source_phv.';
   v_fix                   varchar2(100):= upper('&&fix.');
   v_force                 varchar2(100):= upper('&&force.');

   cursor existing_spbs is
      select sql_handle,plan_name
      from   dba_sql_plan_baselines b,
             v$sqlarea              s
      where  s.exact_matching_signature = b.signature
      and    s.sql_id                   = v_target_sqlid
      and    enabled = 'YES';

   cursor sqlid_in_cache is
      select sql_id
      from   v$sqlarea s
      where  s.sql_id = v_target_sqlid
      or     (s.sql_id = v_source_sqlid and s.plan_hash_value = v_source_phv);

   cursor get_text is
      select replace(sql_fulltext, chr(00), ' ') full_sql_text
      from   v$sqlarea
      where sql_id = v_target_sqlid
      and rownum = 1;

   cursor spb_plans is
      select t.plan_table_output pout
      from   table(dbms_xplan.display_sql_plan_baseline(v_newhandle,null,'BASIC')) t
      where t.plan_table_output like 'Plan name%'
      or    t.plan_table_output like 'Plan hash%'
      or    t.plan_table_output like 'Enabled%';

begin
   if (v_fix != 'FIX' and v_fix != 'NOFIX')
   then
      raise_application_error (-20003, 'Parameter number 4 must be FIX or NOFIX'); 
   end if;

   if (v_fix = 'FIX')
   then
      v_fix_yn := 'YES';
   end if;

   if (v_force != 'FORCE' and v_force != 'NOFORCE')
   then
      raise_application_error (-20004, 'Parameter number 5 must be FORCE or NOFORCE');
   end if;

   dbms_output.put_line('...'); 
   for rec in sqlid_in_cache
   loop
      dbms_output.put_line('... Found SQL ID '||rec.sql_id);
      v_found_sqlids := v_found_sqlids + 1;
   end loop;
   if (v_found_sqlids != 2)
   then
      raise_application_error (-20001, 'Target SQL_ID or source SQL_ID/Plan not found in cursor cache');
   end if;
   --
   -- Figure out whether it's standard edition 12.2 or above
   --
   select decode(count(*),0,'NO','YES')
   into   v_supported_std_ed
   from   v$version
   where  banner like '%Oracle Database%Standard Edition%' 
   and    banner not like 'Oracle Database 11g%'
   and    banner not like 'Oracle Database 12c% Release 12.1%';    

   select decode(count(*),0,'NO','YES')
   into   v_std_edition
   from   v$version
   where  banner like 'Oracle Database%Standard Edition%';

   if (v_std_edition = 'YES' and v_supported_std_ed = 'NO')
   then
      raise_application_error (-20002, 'This version of Standard Edition does not support SQL plan management');
   end if;

   dbms_output.put_line('...'); 
   dbms_output.put_line('...Disable existing SQL Plan Baslines for target SQL statement ID: '||v_target_sqlid);
   dbms_output.put_line('...[In Standard Edition, existing SQL Plan Basline will be dropped]');
   for rec in existing_spbs
   loop
      if (v_force != 'FORCE')
      then
         raise_application_error (-20005, 'NOFORCE specified and there are existing SQL plan baselines for target SQL statement. Plan baseline name: '||rec.plan_name);
      end if;
      if (v_supported_std_ed = 'YES')
      then
         dbms_output.put_line('...... Drop SPB '||rec.sql_handle||' '||rec.plan_name);
         v_np := dbms_spm.drop_sql_plan_baseline(rec.sql_handle, rec.plan_name);
      else
         dbms_output.put_line('...... Disable SPB '||rec.sql_handle||' '||rec.plan_name);
         v_np := dbms_spm.alter_sql_plan_baseline(rec.sql_handle,rec.plan_name,'enabled','NO');
      end if;
   end loop;

   dbms_output.put_line('...'); 
   dbms_output.put_line('... Create SPB with the target SQL text and the source plan');
   for rec in get_text
   loop
      -- We expect only one...
      dbms_output.put_line('... Create SPB with FIXED = '||v_fix_yn);
      v_np := dbms_spm.load_plans_from_cursor_cache(fixed=>v_fix_yn,sql_id=>v_source_sqlid,plan_hash_value=>v_source_phv, sql_text=>rec.full_sql_text);
   end loop;

   dbms_output.put_line('... SQL plan baselines for target SQL statement:');
   open existing_spbs;
   fetch existing_spbs into v_newhandle, v_planname;
   close existing_spbs;
--
-- Display information on SPB
--   
   for rec in spb_plans
   loop
      dbms_output.put_line('...... '||rec.pout);
   end loop;

   dbms_output.put_line('-- '); 
   dbms_output.put_line('-- '); 
   dbms_output.put_line('-- To export SQL plan baselines, first create a staging table...'); 
   dbms_output.put_line('-- '); 
   dbms_output.put_line('exec dbms_spm.create_stgtab_baseline(''spm_staging_table'')'); 
   dbms_output.put_line('-- '); 
   dbms_output.put_line('-- To pack the accepted SQL plan baseline...'); 
   dbms_output.put_line('-- '); 
   dbms_output.put_line('declare n pls_integer; begin n := dbms_spm.pack_stgtab_baseline(table_name=>''spm_staging_table'',plan_name=>'''||v_planname||'''); end;'); 
   dbms_output.put_line('/');
   dbms_output.put_line('-- '); 
   dbms_output.put_line('-- To pack all plan baselines for target SQL statement...'); 
   dbms_output.put_line('-- '); 
   dbms_output.put_line('declare n pls_integer; begin n := dbms_spm.pack_stgtab_baseline(table_name=>''spm_staging_table'',sql_handle=>'''||v_newhandle||'''); end;'); 
   dbms_output.put_line('/');
   
end;
/
