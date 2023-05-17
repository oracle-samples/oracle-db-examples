--
-- This script sets up a SQL statement with a non-reproducible plan 
-- It does this by dropping an index used in the SQL plan baseline plan
-- Be sure to run this script on a TEST SYSTEM ONLY - since it drops SQL plan baselines
--
set echo on
set tab off
set pagesize 1000
set linesize 200
set trims on

var bindv number
var sqlid varchar2(50)

exec select 100 into :bindv from dual;

DECLARE
  l_plans_dropped  PLS_INTEGER;
BEGIN
  FOR REC IN (SELECT DISTINCT SQL_HANDLE FROM DBA_SQL_PLAN_BASELINES where sql_text like '%SPM_TEST%')
  LOOP
      L_PLANS_DROPPED := DBMS_SPM.DROP_SQL_PLAN_BASELINE (
        sql_handle => rec.sql_handle,
        PLAN_NAME  => NULL);
  END LOOP;
END;
/

drop table example_spm_table purge;

create table example_spm_table (id number(10), num number(10), num2 number(10));
create unique index spm_tab_pk on example_spm_table(id);
create index spm_tab_num1 on example_spm_table(num1);

begin
  for i in 1..1000
  loop
    insert into example_spm_table values (i,i,i);
  end loop;
end;
/
commit;

exec dbms_stats.gather_table_stats (ownname=>null,tabname=>'example_spm_table');

select /* SPM_TEST */ num from example_spm_table where id = :bindv;

declare
  r number;
begin
  r:=DBMS_SPM.LOAD_PLANS_FROM_CURSOR_CACHE (attribute_name=>'SQL_TEXT',attribute_value=>'select /* SPM_TEST */ num from example_spm_table where id = :bindv');
end;
/

drop index spm_tab_pk;

select /* SPM_TEST */ num from example_spm_table where id = :bindv;

exec select sql_id into :sqlid from v$sqlarea where sql_text = 'select /* SPM_TEST */ num from example_spm_table where id = :bindv';

select :sqlid from dual;

select sql_text,accepted from dba_sql_plan_baselines where sql_text like '%SPM_TEST%';

select sql_id from v$sql where sql_text = 'select /* SPM_TEST */ num from example_spm_table where id = :bindv';
