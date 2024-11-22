-- TO USE THIS TESTCASE:
--   Do not use if you already have a user called TEST_USER or tablespace TEST_TBS

-- Change the system password if necessary
-- change the directory names used in "host del ...", "create tablespace ..." and "create directory ..."
-- change the "del" to "rm" if using linux
-- before re-running the script, delete the .dmp and .log files created in the EXPDMP directory

connect system/oracle

drop user test_user cascade;

drop tablespace test_tbs including contents;

host del G:\APP\RAFORD\ORADATA\ORCL\TEST_TBS01.DBF

create tablespace test_tbs datafile 'G:\APP\RAFORD\ORADATA\ORCL\TEST_TBS01.DBF' size 10M autoextend on;

create user test_user identified by test_user default tablespace test_tbs temporary tablespace temp quota unlimited on test_tbs;

grant connect,resource,ctxapp to test_user;

create or replace directory expdmp as 'C:\Users\raford';

connect test_user/test_user

create table foo (docid number, bar varchar2(200))
  partition by hash(docid)
  ( partition p1,
    partition p2
  );  

insert into foo values (1, 'the quick brown fox');
insert into foo values (2, 'jumps over the lazy dog');

create index foobar on foo(bar) indextype is ctxsys.context;

connect system/oracle

alter tablespace test_tbs read only;

host expdp system/oracle directory=expdmp dumpfile=expdp.dmp transport_tablespaces=test_tbs transport_full_check=y logfile=expdp.log
