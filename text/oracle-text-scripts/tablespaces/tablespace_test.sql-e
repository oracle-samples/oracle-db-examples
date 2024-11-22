connect system/welcome1

drop user testuser cascade;

drop tablespace ts including contents and datafiles;

-- drop tablespace ts_tde including contents and datafiles;

drop tablespace ts_old including contents and datafiles;

create tablespace ts datafile 'K:\oracle\oradata\ts.dbf' size 10m autoextend on;

create tablespace ts_tde datafile 'K:\oracle\oradata\ts_tde.dbf' size 10m autoextend on encryption using 'AES256' default storage(encrypt);

create user testuser identified by testuser default tablespace ts temporary tablespace temp quota unlimited on ts quota unlimited on ts_tde;

grant connect,resource,ctxapp to testuser;

connect testuser/testuser

create table foo (bar varchar2(20));
insert into foo values ('x');

create index foobtree on foo(bar);
create index footext on foo(bar) indextype is ctxsys.context;

column segment_name format a25
column index_name format a25

select segment_name, segment_type, tablespace_name from user_segments;

connect system/welcome1

alter tablespace ts rename to ts_old;

alter tablespace ts_tde rename to ts;

alter user testuser default tablespace ts;

connect testuser/testuser

create table newtab (x number);
insert into newtab values (1);

select segment_name, segment_type, tablespace_name from user_segments;

select index_name, tablespace_name from user_indexes;

-- alter index foobtree modify default attributes tablespace ts;

alter table foo move tablespace ts;

alter index foobtree rebuild tablespace ts;

alter index footext rebuild;

select segment_name, segment_type, tablespace_name from user_segments;

select index_name, tablespace_name from user_indexes;

connect system/welcome1

drop tablespace ts_old including contents and datafiles;

connect testuser/testuser

select index_name, tablespace_name from user_indexes;
