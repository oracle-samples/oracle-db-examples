-- A Staging Index for Oracle Text
-- -------------------------------

-- This code sample demonstrates the use of a secondary index to create "near real time" updates on a text-indexed table

-- With Oracle Text there is usually a trade-off between update frequency, and the fragmentation of an index
-- Users would like to have their updates available for searching immediately.
-- DBAs would prefer to have SYNCs spaced widely apart to avoid fragmentation of the index

-- We create a "staging" table with its index, and triggers to copy all updates and inserts into that staging table
-- The index on the staging table has "sync (on commit)" to ensure it keeps up-to-date
-- Queries do a UNION between the main table and the staging table
-- When a SYNC is called for the main table, all rows inserted or updated in the staging table before the
-- start of the SYNC are deleted.

-- Ideally the staging table will have suitable STORAGE clauses such that its index tables are always
-- kept in memory.

-- This example assumes that there is a primary key contraint on the main table and the staging table. 
-- If the main table does not have a primary key constraint, then the implications are:
--    The staging table cannot have a primary key constraint either, or we would not be able to handle
--       updates on two identical rows.
--    Therefore we cannot rely on a "dup_value_in_index" exception to tell us if a row is updated twice
--    We would probably need to keep track of main-table rowids in the staging table instead

-- There is a small window for duplicate rows to be found in both tables. After the main table sync 
-- has completed, but before the sync-on-commit of the staging table is complete, we may get the same 
-- row back from the main table and the staging table. However, this should not be an issue as the
-- UNION will ignore duplicates.

-- change the SYSTEM password in the line below

connect system/manager

drop user testuser cascade;

create user testuser identified by testuser 
   default tablespace users 
   temporary tablespace temp 
   quota unlimited on users;

grant connect, resource, ctxapp to testuser;
grant execute on ctx_ddl to testuser;

connect testuser/testuser

-- this is our main table

create table main_table (id number primary key, author varchar2(255), text varchar2(4000));

insert into main_table values (1, 'John Smith', 'The quick brown fox jumps over the lazy dog');

-- this is our staging table - identical to the main table but with an update_time column added

create table stage_table (id number primary key, author varchar2(255), text varchar2(4000), update_time timestamp);

-- create triggers to copy updates and inserts from main_table to stage_table

create or replace trigger main_table_insert_trigger
  after insert on main_table
  for each row
begin
  insert into stage_table values (:new.id, :new.author, :new.text, systimestamp);
end;
/
-- list
show errors

create or replace trigger main_table_update_trigger
  after update on main_table
  for each row
begin
  insert into stage_table values (:new.id, :new.author, :new.text, systimestamp);
  exception when dup_val_on_index then
    update stage_table set author = :new.author, text = :new.text, update_time = systimestamp where id = :new.id;
end;
/
-- list
show errors

-- create indexes on main and stage tables. Main has manual sync, stage has sync on commit

create index main_index on main_table (text) indextype is ctxsys.context;

create index stage_index on stage_table (text) indextype is ctxsys.context
parameters ('sync (on commit)');

-- procedure to sync the main table and clean up the staging table

create or replace procedure sync_main_index is
  timest timestamp;
begin
  timest := systimestamp;
  ctx_ddl.sync_index('main_index');
  delete from stage_table where update_time <= timest;
  commit;
  -- optionally
  ctx_ddl.optimize_index('stage_index', 'FULL');
end;
/
-- list 
show errors


-- column layout stuff for SQL*Plus:

column id format 999
column author format a15
column text format a50

-- Now test it.
-- Insert a row into the main table.  We expect it to get copied into the stage table which is
-- then synced as soon as we commit

insert into main_table values (2, 'John Bloggs', 'The quick antelope gallops across the plains');
commit;

-- Search for "quick".  We expect to find 2 rows

select id, author, text from main_table where contains( text, 'quick' ) > 0
union
select id, author, text from stage_table where contains( text, 'quick' ) > 0
/

-- Call procedure to sync the main index and delete from the staging table

exec sync_main_index

-- Check the search returns the same rows

select id, author, text from main_table where contains( text, 'quick' ) > 0
union all
select id, author, text from stage_table where contains( text, 'quick' ) > 0
/

-- Now test an update

update main_table set text = 'The slow brown fox jumps over the lazy dog' where id=1;
commit;

-- Search for "quick" should find row 2, search for "slow" should find row 1

select id, author, text from main_table where contains( text, 'quick' ) > 0
union
select id, author, text from stage_table where contains( text, 'quick' ) > 0
/

select id, author, text from main_table where contains( text, 'slow' ) > 0
union
select id, author, text from stage_table where contains( text, 'slow' ) > 0
/

-- Do multiple updates to a row to make sure last one counts

update main_table set text = 'The fast antelope gallops across the plains' where id=2;
update main_table set text = 'The slow antelope gallops across the plains' where id=2;
commit;

-- Search for slow should now pick up both rows

select id, author, text from main_table where contains( text, 'slow' ) > 0
union
select id, author, text from stage_table where contains( text, 'slow' ) > 0
/

-- and the same after a sync

exec sync_main_index

select id, author, text from main_table where contains( text, 'slow' ) > 0
union
select id, author, text from stage_table where contains( text, 'slow' ) > 0
/

-- This is sample code provided with no warranty express or implied.
-- You are free to reuse any part of this code as you wish

-- Comments and corrections welcomed
-- Roger Ford roger.ford@oracle.com 2013-03-12


