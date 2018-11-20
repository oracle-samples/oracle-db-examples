--
-- Partitioned version of the tables
--
drop table p_employees purge;
drop table p_tasks purge;
create table p_employees (id number(10) not null, ename varchar2(100) not null, etype number(10) not null, details varchar2(1000))
partition by range (id)
(partition p1 values less than (5000)
,partition p2 values less than (20000));
create table p_tasks (id number(10) not null, tname varchar2(100) not null, emp_id number(10) not null, ttype number(10) not null, details varchar2(1000))
partition by range (id)
(partition p1 values less than (10000)
,partition p2 values less than (50000));

begin
  for i in 1..10000
  loop
     insert into p_employees values (i,
                                   'Employee Name '||i, 
                                   mod(i,500) + 1, 
                                   dbms_random.string('u',1000));
  end loop;
  for i in 1..20000
  loop
     insert into p_tasks values (i,'Task Name '||i, mod(i,10000) + 1, mod(i,500) + 1, dbms_random.string('u',1000));
  end loop;
  commit;
end;
/

@@p_ind


exec dbms_stats.gather_table_stats(user,'p_employees');
exec dbms_stats.gather_table_stats(user,'p_tasks');
