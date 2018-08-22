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
     dbms_stats.delete_table_stats(user,r.table_name);
     dbms_output.put_line('Drop Stats: '||r.table_name);
  end loop;
end;
/

@stats
