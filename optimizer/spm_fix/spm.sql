var rep clob
set linesize 250
set pagesize 10000
set trims on
set tab off
set long 1000000
column report format a200
set echo on

exec select '' into :rep from dual;

--
-- This example assumes that you have the bad plan in the
-- cursor cache but this is not essential. Take a look
-- at the documentation for DBMS_SPM because there are a 
-- large number of options for creating the initial SQL plan
-- baseline. Also, you might even have a SQL plan baseline already.
--
-- The example SQL ID hard coded in this example
--

set linesize 100
set trims on
set tab off
set pagesize 1000
column plan_table_output format 95

var childid varchar2(100)
var childnum number
--
-- The SQL_ID of our SQL statement
--
exec :childid := '0ptw8zskuh9r4';

exec select max(child_number) into :childnum from v$sql where sql_id = :childid;

SELECT *
FROM table(DBMS_XPLAN.DISPLAY_CURSOR(FORMAT=>'BASIC', SQL_ID=>:childid, cursor_child_no=>:childnum));

accept myphv char prompt 'Enter the plan hash value of the bad NL plan (above): '

DECLARE
   tname varchar2(1000);
   ename varchar2(1000);
   n number;
   sig number;
   sqlid varchar2(1000) := :childid;
   phv   number         := &myphv;
   handle varchar2(1000);
   nc     number;
BEGIN 
   select count(*) into nc
   from   v$sql
   where sql_id = sqlid
   and   plan_hash_value = phv;
  
   if (nc = 0) 
   then
      raise_application_error(-20001, 'The SQL_ID/PHV combination not found in V$SQL');
   end if;

   select exact_matching_signature into sig 
   from   v$sqlarea 
   where  sql_id = sqlid;

-- Enabled=NO because we will assume that this is a bad plan

   n := dbms_spm.load_plans_from_cursor_cache(
                  sql_id => sqlid, 
                  plan_hash_value=> phv, 
                  enabled => 'no');

   select distinct sql_handle 
   into   handle 
   from   dba_sql_plan_baselines 
   where  signature = sig;

   tname := DBMS_SPM.CREATE_EVOLVE_TASK(sql_handle=>handle); 

   DBMS_SPM.SET_EVOLVE_TASK_PARAMETER( 
      task_name => tname,
      parameter => 'ALTERNATE_PLAN_BASELINE', 
      value     => 'EXISTING');

   DBMS_SPM.SET_EVOLVE_TASK_PARAMETER( 
      task_name => tname,
      parameter => 'ALTERNATE_PLAN_SOURCE', 
      value     => 'CURSOR_CACHE+AUTOMATIC_WORKLOAD_REPOSITORY');

   DBMS_SPM.SET_EVOLVE_TASK_PARAMETER( 
      task_name => tname,
      parameter => 'ALTERNATE_PLAN_LIMIT', 
      value     => 'UNLIMITED');

   ename := DBMS_SPM.EXECUTE_EVOLVE_TASK(tname);

   n := DBMS_SPM.IMPLEMENT_EVOLVE_TASK(tname);

   select DBMS_SPM.REPORT_EVOLVE_TASK(task_name=>tname) into :rep from dual;
END; 
/

set echo off
--
PROMPT Note!
PROMPT Take a look at the following report to confirm that the previous plan
PROMPT passes the performance criteria to be accepted. 
PROMPT Be aware that on some systems the difference may not be significant 
PROMPT enough to warrant acceptance of the SQL plan baseline.
PROMPT If this happens in your case, you should increase the number of rows
PROMPT in the test tables to boost the performance difference between
PROMPT the nested loop and hash join versions of the test query.
--
select :rep report from dual;
