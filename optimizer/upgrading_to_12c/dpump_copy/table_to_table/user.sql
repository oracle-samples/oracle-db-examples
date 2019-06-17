connect / as sysdba

drop user s1 cascade;

create user s1 identified by s1;
grant dba to s1;

connect s1/s1
create table t1 (id number(10),c1 varchar2(15),c2 varchar2(10),c3 varchar2(10));
insert into t1 values (1,'X','X','A');
insert into t1 values (2,'Y','Y','B');
insert into t1 values (3,'Z','Z','C');
begin
   for i in 1..10000
   loop
     insert into t1 values (4,'W'||i,'W'||i,'D');
   end loop;
end;
/
commit;
--
-- We'll create statistics on t2 but they will be stale
--
create table t2 as select * from t1 where 1 = -1;
create index t2i on t2 (c1);
exec dbms_stats.gather_table_stats(ownname=>null,tabname=>'t1',method_opt=>'for all columns size 1');
insert into t2 select * from t1 where rownum<1000;
commit;
--
exec dbms_lock.sleep(5)
--
--
-- 
create index t1i on t1 (c1);
--
-- This query will generate column usage information for S1.T1
-- so we should get a histogram when we gather stats with 
-- FOR ALL COLUMNS SIZE AUTO
--
select count(*) from t1 where c1 between 'W1' and 'W5';
--
-- Create extended stats
--
select dbms_stats.create_extended_stats(user,'t1','(c1,c2)') from dual;
--
-- Gather stats on S1.T1
--
exec dbms_stats.gather_table_stats(ownname=>null,tabname=>'t1',method_opt=>'for all columns size auto');
--
-- Set a table preference
--
select dbms_stats.get_prefs ('TABLE_CACHED_BLOCKS','s1','t1') from dual;
exec dbms_stats.set_table_prefs ('s1','t1','TABLE_CACHED_BLOCKS',50)
select dbms_stats.get_prefs ('TABLE_CACHED_BLOCKS','s1','t1') from dual;
