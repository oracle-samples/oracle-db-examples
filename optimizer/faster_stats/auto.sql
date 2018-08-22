@cusr
set serveroutput on

declare
  cursor c1 is
    select table_name
    from   user_tables
    where table_name like 'BIGT%';
begin
  for r in c1
  loop
     dbms_stats.set_table_prefs(user,r.table_name,'degree',DBMS_STATS.AUTO_DEGREE);
     dbms_output.put_line('Auto: '||r.table_name);
  end loop;
end;
/
