--
-- Creates column groups for a parsed SQL statement
-- where the plan is available in the PLAN_TABLE
-- Parameter:
--     Y/N where Y - will create the column groups immediately
--               N - will print the column group creation script only 
--
set long 100000
var create_now varchar2(1)

exec dbms_stats.flush_database_monitoring_info;
exec dbms_lock.sleep(2)

exec select decode(nvl(upper('&1'),'N'),'N','N','Y') into :create_now from dual;

set serveroutput on
declare 
  r clob;
  cursor c1 is
    select distinct statement_id,object_name,object_owner
    from   plan_table
    where  object_type = 'TABLE'
    and    timestamp = (select max(timestamp) from plan_table)
    order by object_name;
begin
  for rec in c1
  loop
     r := dbms_stats.report_col_usage(rec.object_owner,rec.object_name) ;
     dbms_output.put_line('-- ===========================================================');
     dbms_output.put_line('--     Table Name  : '||rec.object_name);
     dbms_output.put_line('/*');
     dbms_output.put_line(r);
     dbms_output.put_line('*/');
     if :create_now = 'Y'
     then
        select dbms_stats.create_extended_stats(rec.object_owner,rec.object_name) into r from dual;
        dbms_output.put_line(r);
     else
        dbms_output.put_line('select dbms_stats.create_extended_stats('''||rec.object_owner||''','''||rec.object_name||''') es from dual;');
     end if;
  end loop;
  dbms_output.put_line('-- === Stats need to be regathered on the following tables');
  for rec in c1
  loop
     -- In theory, we could go ahead and gather stats here rather than just reporting the need.
     -- In addition, we could choose to create the new stats unpublished if we wanted
     -- to temporariy hide the change from the workload.
     dbms_output.put_line('exec dbms_stats.gather_table_stats('''||rec.object_owner||''','''||rec.object_name||''')');
  end loop;
end;
/
set serveroutput off
