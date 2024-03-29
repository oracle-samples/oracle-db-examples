-- script to check moving of text table and index to new tablespace works, and requires index rebuild

-- set system password in line below
-- this scripts drops any existing user called TESTUSER and tablespace NEWTBSP
-- expects a USERS tablespace. Change that to sysaux if you're in ADE and haven't added a USERS tablespace

connect system/oracle

set echo on
set timing on

-- expected to give error on first run
drop user testuser cascade;
-- expected to give error on first run
drop tablespace newtbsp including contents and datafiles;

-- following procedure creates a tablespace NEWTBSP in the same directory as SYSTEM
-- replace with hard-coded CREATE TABLESPACE if you don't trust this!

declare
  filename_prefix varchar2(256);
begin
  select regexp_substr(file_name, '.*[\\/]') 
    into filename_prefix from sys.dba_data_files
    where tablespace_name = 'SYSTEM';
  execute immediate ('create tablespace newtbsp datafile ''' 
       || filename_prefix || 
       'NEWTBSP.DBF'' size 100m autoextend on segment space management auto');
end;
/

column tablespace_name format a20
column file_name format a40

-- check we've created new tablespace OK
select tablespace_name, file_name from sys.dba_data_files;

-- create user
create user testuser identified by testuser default tablespace users temporary tablespace temp
quota unlimited on users quota unlimited on newtbsp;

grant connect,resource,ctxapp,dba to testuser;

connect testuser/testuser

create table foo(id number, bar varchar2(50)) tablespace users
partition by range (id)
(
  partition p1 values less than ( 1000     ) tablespace users,
  partition p2 values less than ( 10000    ) tablespace users,
  partition p3 values less than ( maxvalue ) tablespace users
)
/

-- insert 100k rows into the table, just so we can see whether rebuild is instant or not
-- (it isn't)

begin
  for i in 1..100000 loop
    insert into foo values (i, 'hello world'||to_char(i));
  end loop;
end;
/

exec ctx_ddl.create_preference('store1', 'BASIC_STORAGE')
exec ctx_ddl.set_attribute('store1', 'I_TABLE_CLAUSE', 'tablespace users')
exec ctx_ddl.set_attribute('store1', 'I_INDEX_CLAUSE', 'tablespace users')
exec ctx_ddl.set_attribute('store1', 'R_TABLE_CLAUSE', 'tablespace users')
exec ctx_ddl.set_attribute('store1', 'K_TABLE_CLAUSE', 'tablespace users')
exec ctx_ddl.set_attribute('store1', 'N_TABLE_CLAUSE', 'tablespace users')

-- create the index

create index fooindex on foo(bar) indextype is ctxsys.context
parameters ('storage store1')
local (
  partition p1 parameters ('storage store1'),
  partition p2 parameters ('storage store1'),
  partition p3 parameters ('storage store1')
  )
;

set linesize 160
column owner format a20
column segment_name format a30
column tablespace_name format a20

-- check all objects are in USERS tablespace

select owner, segment_name, tablespace_name from dba_segments 
where segment_name like '%FOOINDEX%'
and owner = 'TESTUSER';

select table_name, tablespace_name from user_tables;
select index_name, tablespace_name from user_indexes;
select segment_name, tablespace_name from user_segments;

-- now create new storage preference using NEWTBSP tablespace

exec ctx_ddl.create_preference('store2', 'BASIC_STORAGE')
exec ctx_ddl.set_attribute('store2', 'I_TABLE_CLAUSE', 'tablespace newtbsp')
exec ctx_ddl.set_attribute('store2', 'I_INDEX_CLAUSE', 'tablespace newtbsp')
exec ctx_ddl.set_attribute('store2', 'R_TABLE_CLAUSE', 'tablespace newtbsp')
exec ctx_ddl.set_attribute('store2', 'K_TABLE_CLAUSE', 'tablespace newtbsp')
exec ctx_ddl.set_attribute('store2', 'N_TABLE_CLAUSE', 'tablespace newtbsp')

alter table foo move partition p1 tablespace newtbsp;
alter table foo move partition p2 tablespace newtbsp;
alter table foo move partition p3 tablespace newtbsp;

-- confirm that the index is broken at this point

select * from foo where contains(bar, 'world1') > 0;

-- alter the index.  We expect this to take at least as long as the create index

alter index fooindex rebuild partition p1 parameters('replace storage store2');
alter index fooindex rebuild partition p2 parameters('replace storage store1');
alter index fooindex rebuild partition p3 parameters('replace storage store2');

-- confirm that the index is now working

select * from foo where contains(bar, 'world1') > 0;

-- check tablespace for all objects. We expect p2 to be in users,
-- p1 and p3 in newtbsp

select owner, segment_name, tablespace_name from dba_segments 
where segment_name like '%FOOINDEX%'
and owner = 'TESTUSER'
order by tablespace_name, segment_name
/

select table_name, tablespace_name from user_tables;
select index_name, tablespace_name from user_indexes;
select segment_name, tablespace_name from user_segments;

