create user stest identified by <put_your_password_here>;
grant dba to stest;
grant sysdba to stest;
alter user stest default tablespace big;
