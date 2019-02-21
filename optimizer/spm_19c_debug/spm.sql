set tab off
set pagesize 1000
column plan_table_output format a180
column report format a180
column sql_handle format a30
column plan_name format a40
column sql_text format a80
set linesize 200

begin
  execute immediate 'drop table mytest1';
exception
  when others then
     if sqlcode != -942
     then
       raise;
     end if;
end;
/

create table mytest1 as
select rownum as id, rownum as num from dual connect by rownum < 10000;
commit;

create index mytest1i on mytest1 (id);


declare
  n pls_integer;
begin
  for rec in (select distinct sql_handle from dba_sql_plan_baselines where sql_text like '%MYTESTSQL%')
  loop
     n := dbms_spm.drop_sql_plan_baseline(
          sql_handle => rec.sql_handle,
          plan_name => null);
  end loop;
end;
/


alter session set optimizer_capture_sql_plan_baselines = true;
select /* MYTESTSQL */ sum(num) from mytest1 where id = 10;
select /* MYTESTSQL */ sum(num) from mytest1 where id = 10;
alter session set optimizer_capture_sql_plan_baselines = false;

--
-- Notice that the SQL plan baseline is used
--
explain plan for select /* MYTESTSQL */ sum(num) from mytest1 where id = 10;
select * from table(DBMS_XPLAN.DISPLAY(FORMAT=>'typical'));


select sql_handle,plan_name,sql_text,accepted from dba_sql_plan_baselines where sql_text  like '%MYTESTSQL%';

alter index mytest1i invisible;
select /* MYTESTSQL */ sum(num) from mytest1 where id = 10;
--
-- Notice that the SQL plan baseline plan cannot be reproduced because
-- the index is now hidden - it can't be used.
--
explain plan for select /* MYTESTSQL */ sum(num) from mytest1 where id = 10;
select * from table(DBMS_XPLAN.DISPLAY(FORMAT=>'typical'));

--
-- We have captured a new plan in the SQL Plan History
--
select sql_handle,plan_name,sql_text,accepted from dba_sql_plan_baselines where sql_text  like '%MYTESTSQL%';
--
-- Let's look at the original plan (the one that isn't being used) and the new plan
-- The non-accepted (new) plan is a FULL scan beause the index is hidden
--
select * from dbms_xplan.display_sql_plan_baseline('SQL_460a69f9b993a3a7');
--
-- Now let's see why the old plan isn't being used...
--
-- The 'trick' is to force the SQL statement to use the SQL plan baseline outline
-- using the sql_plan_management_control hidden parameter
-- i.e. - we will apply the outline to the SQL statement and
-- then rely on the hint usage report to tell us which hints in the 
-- SQL plan baseline outline have not been honored.
--
alter session set "_sql_plan_management_control"=4;
explain plan for select /* MYTESTSQL */ sum(num) from mytest1 where id = 10;
select * from table(DBMS_XPLAN.DISPLAY(FORMAT=>'typical'));
alter session set "_sql_plan_management_control"=0;
