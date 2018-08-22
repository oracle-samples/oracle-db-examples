--
-- Create some large tables
--
@cusr
@tab_count
set echo on
set serveroutput on

declare
  cursor c1 is
    select table_name 
    from   user_tables
    where table_name like 'BIGT%';
begin
  for r in c1 
  loop
     execute immediate 'drop table '||r.table_name||' purge';
     dbms_output.put_line('Dropped: '||r.table_name);
  end loop;
end;
/

declare
  tabname varchar2(100);
  tab_not_exist exception;
  pragma exception_init(tab_not_exist, -942);
begin
  for i in 1..:tcount
  loop
     tabname := 'BIGT'||i;
     begin
        execute immediate 'drop table ' || tabname;
     exception
        when tab_not_exist then null;
     end;
     execute immediate 'create table '||tabname|| ' as select rownum n from dual connect by rownum<(1000000+'||i||'*150000)';
     execute immediate 'create index '||tabname||'_indx1 on '||tabname||'(n)';
     commit;
     for j in 1..10
     loop
        execute immediate 'alter table '||tabname||' add ln'||j||' as (ln(n+'||j||'))';
     end loop;
     execute immediate 'create index '||tabname||'_indx2 on '||tabname||'(ln1)';
     dbms_stats.delete_table_stats(user,tabname);
     dbms_output.put_line('Built table: '||tabname);
  end loop;
end;
/ 
