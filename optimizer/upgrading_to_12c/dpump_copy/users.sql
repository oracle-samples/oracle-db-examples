connect / as sysdba

drop user s1 cascade;
drop user s2 cascade;

create user s1 identified by s1;
grant dba to s1;

create user s2 identified by s2;
grant dba to s2;

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
-- Set a table preference to check that it is copied from one schema to another
--
select dbms_stats.get_prefs ('TABLE_CACHED_BLOCKS','s1','t1') from dual;
exec dbms_stats.set_table_prefs ('s1','t1','TABLE_CACHED_BLOCKS',50)
select dbms_stats.get_prefs ('TABLE_CACHED_BLOCKS','s1','t1') from dual;

connect s2/s2
--
-- Create S2.T1 with a slightly different number of rows
--
create table t1 (id number(10),c1 varchar2(15),c2 varchar2(10),c3 varchar2(10));
insert into t1 values (1,'X','X','A');
insert into t1 values (2,'Y','Y','B');
insert into t1 values (3,'Z','Z','C');
begin
   for i in 1..10100
   loop
     insert into t1 values (4,'W'||i,'W'||i,'D');
   end loop;
end;
/
commit;
--
-- We'll get stats on the index, but we won't be gathering stats 
-- on the S2.T1 table because we want to copy everything from S1.T1
--
create index t1i on t1 (c1);

--
-- Let's create some SQL plan directives
--
connect s1/s1

CREATE TABLE spdtab (
  id             NUMBER,
  col1           VARCHAR2(1),
  col2           VARCHAR2(1)
);

INSERT INTO spdtab
SELECT level, 'A', 'B'
FROM   dual
CONNECT BY level <= 10;
COMMIT;

INSERT INTO spdtab
SELECT 10+level, 'C', 'D'
FROM   dual
CONNECT BY level <= 90;
COMMIT;

EXEC DBMS_STATS.gather_table_stats(USER, 'SPDTAB');

SELECT *
FROM   spdtab
WHERE  col1 = 'A'
AND    col2 = 'B';

connect s2/s2

CREATE TABLE spdtab (
  id             NUMBER,
  col1           VARCHAR2(1),
  col2           VARCHAR2(1)
);

