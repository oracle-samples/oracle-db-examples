--  Assumes we have two databases, r192 and r193, and that both are known
--  to the SQL Net listener

--  This testcase uses EZConnect syntax - @hostname:port/SID
--  Note that the typical port number is 1521, not 1523 as used here.

--  You would need to change this testcase to replace all passwords (oracle here)
--  and the SIDs of your two databases
--  Tested on where both databases are 19c and with 11.2 / 12.2 databases

connect system/oracle@localhost:1523/r192

drop user distuser cascade;

grant connect,resource,ctxapp,unlimited tablespace,create database link to distuser identified by distuser;

connect system/oracle@localhost:1523/r193

drop user distuser cascade;

grant connect,resource,ctxapp,unlimited tablespace,create database link to distuser identified by distuser;

connect distuser/distuser@localhost:1523/r192
create table tab2 (id2 number primary key, text2 varchar2(200));

insert into tab2 values (1, 'hello world');

create index tab2index on tab2(text2) indextype is ctxsys.context;

connect distuser/distuser@localhost:1523/r193
create table tab3 (id3 number primary key, text3 varchar2(200));

insert into tab3 values (1, 'foo bar');

create database link db2 connect to distuser identified by distuser using 'localhost:1523/r192'; 

-- works
select * from tab2@db2 t2 
where contains@db2 (text2, 'hello') > 0;

-- works if we use a sub-query
select * from tab3 t3
where t3.id3 in 
  (select t2.id2 from tab2@db2 t2);

-- doesn't work if we use a join
-- returns ORA-00949: illegal reference to remote database
select * from tab3 t3, tab2@db2 t2 
where contains@db2 (text2, 'hello') > 0 
and t3.id3 = t2.id2;

