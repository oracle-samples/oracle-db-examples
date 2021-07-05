--
-- Creates column groups for a parsed SQL statement
-- where the plan is available in the PLAN_TABLE
-- Parameter:
--     Y/N where Y - will create the column groups immediately
--               N - will print the column group creation script only 
--
set long 100000
set feedback off
var create_now varchar2(1)
var sqlset varchar2(100)

exec select '&1' into :sqlset from dual;
exec select decode(nvl(upper('&2'),'N'),'N','N','Y') into :create_now from dual;

set serveroutput on
declare 
  time_limit_sec number := 30;
  cursor c1 is
    select distinct object_owner owner, object_name table_name 
    from   user_sqlset_plans
    where  object_type = 'TABLE' 
    and    sqlset_name = :sqlset
    order by object_owner,object_name;
  r clob;
begin
  dbms_stats.seed_col_usage(:sqlset,user,time_limit_sec);
  dbms_stats.flush_database_monitoring_info;

  for rec in c1
  loop
     r := dbms_stats.report_col_usage(rec.owner,rec.table_name) ;
     dbms_output.put_line('-- ===========================================================');
     dbms_output.put_line('--     Table Name  : '||rec.table_name);
     dbms_output.put_line('/*');
     dbms_output.put_line(r);
     dbms_output.put_line('*/');
     if :create_now = 'Y'
     then
        select dbms_stats.create_extended_stats(rec.owner,rec.table_name) into r from dual;
        dbms_output.put_line('Extension created: '||r);
     else
        dbms_output.put_line('select dbms_stats.create_extended_stats('''||rec.owner||''','''||rec.table_name||''') es from dual;');
     end if;
  end loop;
  dbms_output.put_line('-- === Stats need to be regathered on the following tables');
  for rec in c1
  loop
     dbms_output.put_line('exec dbms_stats.gather_table_stats('''||rec.owner||''','''||rec.table_name||''')');
  end loop;
end;
/
set serveroutput off
