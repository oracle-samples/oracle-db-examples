create user stest identified by stest;
grant dba to stest;
grant sysdba to stest;
alter user stest default tablespace big;
