-- Example of modifying a column without losing a text index

-- We will save the text index tables, drop the text index, modify the table
-- then recreate the index with nopopulate option, and move the previous index tables back.

-- This is NOT SUPPORTED. It may not even work for all tables, but we believe it does.
-- This script makes internal changes to the Text Data Dictionary, and should therefore
-- be run with the utmost care. It is for use in the "last resort" where reindexing a table
-- is really not practical. A complete database backup is ESSENTIAL before running this 
-- script on a live system

-- example uses a table call MYTAB owned by user ROGER. For the purpose of example
-- this table will be created from scratch

set echo on

-- the user needs to be able to read and update dr$index table to reset max docid

connect / as sysdba
grant select,update on ctxsys.dr$index to roger;

connect roger/roger

-- create an OS file (this is Windows-specific) which we will later index

$ echo hello world > c:\indexfile1.txt

-- drop will fail first time round, doesn't matter

drop table mytab1;

-- now create the table, load the name of the external file, and create
-- the text index

create table mytab1 (pk number primary key, text varchar2(132));

insert into mytab1 values (1, 'c:\indexfile1.txt');

create index myidx1 on mytab1 (text)
indextype is ctxsys.context
parameters ('datastore ctxsys.file_datastore filter ctxsys.null_filter');

select count(*) "Number of index errors" from ctx_user_index_errors
where err_index_name = 'MYIDX1';

-- drop the original datafiles

$ del c:\indexfile1.txt

-- this is the "current state" - we have a table and index, but don't have the
-- original data files. We need to change the definition of the text-indexed column

pause

-- first we need to save some details from the text data dictionary
-- docid_count is probably not too important, but nextid is essential
-- to avoid repeated textkey values in the $K, $R tables

-- change ROGER and MYIDX1 here to suit username and indexname in your env

variable v_docid_count number
variable v_nextid number

begin
  select idx_docid_count, idx_nextid into :v_docid_count, :v_nextid
    from ctxsys.dr$index i, all_users u
    where u.user_id = i.idx_owner#
    and u.username = 'ROGER'
    and idx_name = 'MYIDX1';
end;
/

pause

-- test queries before changing anything

select * from mytab1 where contains (text, 'hello') > 0;

pause 

-- now save the text index tables by renaming them. That means when
-- we drop the index we'll still keep these tables (drop index doesn't
-- mind if it can't find the tables it thinks it should be dropping)

rename dr$myidx1$i to dr$myidx1_save$i;
rename dr$myidx1$k to dr$myidx1_save$k;
rename dr$myidx1$r to dr$myidx1_save$r;

-- $X: can't rename an index directly, have to do it like this:
alter index dr$myidx1$x rename to dr$myidx1_save$x;

pause 

-- Now we'll drop the text index having saved all the index tables

drop index myidx1;

pause

-- and modify the column definition, which we can now do as it doesn't
-- have a text index on it any more

alter table mytab1 modify text varchar2(4000);

pause

-- Now we'll create a new index using the NOPOPULATE parameter so that
-- it doesn't actually do any indexing

create index myidx1 on mytab1 (text)
indextype is ctxsys.context
parameters ('datastore ctxsys.file_datastore filter ctxsys.null_filter nopopulate')
/

pause 

-- drop the new, empty index tables

drop table dr$myidx1$i;
drop table dr$myidx1$k;
drop table dr$myidx1$r;

pause

-- and put the old ones back in their places

rename dr$myidx1_save$i to dr$myidx1$i;
rename dr$myidx1_save$k to dr$myidx1$k;
rename dr$myidx1_save$r to dr$myidx1$r;
alter index dr$myidx1_save$x rename to dr$myidx1$x;

pause

-- fix the data dictionary with saved values

update ctxsys.dr$index i 
  set idx_docid_count = :v_docid_count,
      idx_nextid = :v_nextid
  where i.idx_id in (
     select i2.idx_id from ctxsys.dr$index i2, all_users u
     where u.user_id = i2.idx_owner#
     and u.username = 'ROGER'
     and i2.idx_name = 'MYIDX1');

-- we should be done.

-- check queries still work

select * from mytab1 where contains (text, 'hello') > 0;

-- do another insert and make sure sync works

pause

$ echo quick brown fox > c:\indexfile2.txt

insert into mytab1 values (2, 'c:\indexfile2.txt');

pause

exec ctx_ddl.sync_index ('myidx1');

pause

select * from mytab1 where contains (text, 'hello') > 0;

pause

select * from mytab1 where contains (text, 'quick') > 0;
