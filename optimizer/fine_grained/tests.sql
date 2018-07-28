set tab on
set trim on
@tab
@q
@sql
set echo on
--
-- CREATE INDEX (visible)
--
create index new1 on t1 (val2) deferred invalidation;
create index new2 on t2 (val2) local deferred invalidation;
set echo off
@sql

pause Press <CR>

@tab
@q
@sql
set echo on
--
-- CREATE INDEX (invisible)
--
create index new1 on t1 (val2) invisible deferred invalidation;
create index new2 on t2 (val2) invisible local deferred invalidation;
set echo off
@sql

pause Press <CR>

@tab
@q
@sql
set echo on
--
-- DROP INDEX
--
drop index t1i deferred invalidation;
drop index t2i deferred invalidation;
set echo off
@sql

pause Press <CR>

@tab
@q
@sql
set echo on
--
-- INDEX UNUSABLE
--
alter index t1i unusable deferred invalidation;
alter index t2i modify partition p1i unusable deferred invalidation;

alter session set CURSOR_INVALIDATION = 'deferred';
alter index t2i modify partition p1i unusable;
alter session set CURSOR_INVALIDATION = 'immediate';

set echo off
@sql

pause Press <CR>

@tab
@q
@sql
set echo on
--
-- INDEX REBUILD
--
alter index t1i rebuild deferred invalidation;
alter index t2i rebuild partition p1i deferred invalidation;
set echo off
@sql


@tab
prompt Get rid of indexes...
set echo on
drop index t1i;
drop index t2i;
set echo off
@q
@sql
set echo on
--
-- TRUNCATE TABLE/PARTITION
--
-- ## NOTE Accepted but might not implemented because T1 is not partitioned...
truncate table t1 deferred invalidation;
alter table t2 truncate partition p1 deferred invalidation;
set echo off
prompt ###  Truncate partition is fine-grained, but truncate table is not
@sql



@tab
prompt Get rid of indexes...
set echo on
drop index t1i;
drop index t2i;
set echo off
@q
@sql
set echo on
--
-- MOVE TABLE/PARTITION
--
-- ## NOTE Accepted but might not implemented...
alter table t1 move deferred invalidation;
alter table t2 move partition p1 deferred invalidation;
set echo off
prompt ###  Truncate partition is fine-grained, but truncate table is not
@sql


@tab
prompt Get rid of indexes...
set echo on
drop index t1i;
drop index t2i;
set echo off
@q
@sql
set echo on
--
-- MOVE TABLE/PARTITION
--
-- ## NOTE Accepted but might not be implemented...
alter table t1 move deferred invalidation;
alter table t2 move deferred invalidation;
set echo off
@sql



@tab
prompt Get rid of indexes...
set echo on
drop index t1i;
drop index t2i;
set echo off
@q
@sql
set echo on
--
-- TRUNCATE NON-PARTITIONED VS PARTITIONED TABLE
--
-- ## NOTE Accepted but might not implemented for non-partitioned table
truncate table t1 deferred invalidation;
truncate table t2 deferred invalidation;
set echo off
prompt ###  Truncate partition is fine-grained, but truncate table is not
@sql

@tab
prompt Get rid of indexes...
set echo on
drop index t1i;
drop index t2i;
set echo off
@q
@sql
set echo on
--
-- ADD PARTITION
--
alter  table t2 add partition p3 values less than (300000) deferred invalidation;
set echo off
@sql


@tab
prompt Get rid of indexes...
set echo on
drop index t1i;
drop index t2i;
alter  table t2 add partition p3 values less than (300000);
set echo off
@q
@sql
set echo on
--
-- DROP PARTITION
--
alter table t2 drop partition p3 deferred invalidation;
set echo off
@sql


@tab
prompt Get rid of indexes...
set echo on
drop index t1i;
drop index t2i;
alter  table t2 add partition p3 values less than (300000);
set echo off
@q
@sql
set echo on
--
-- SPLIT PARTITION 
--
alter table t2 split partition p1 at (50000) into (partition p1,partition p1a) deferred invalidation;
set echo off
@sql

@tab
prompt Get rid of indexes...
set echo on
drop index t1i;
drop index t2i;
alter  table t2 add partition p3 values less than (300000);
set echo off
@q
@sql
set echo on
--
-- MERGE PARTITION
-- Note: hash-ADD, COALESCE should behave in same way - not tested here
--
alter table t2 merge partitions p2 to p3 into partition px deferred invalidation;
set echo off
@sql

@tab
prompt Get rid of indexes...
set echo on
drop index t1i;
drop index t2i;
alter  table t2 add partition p3 values less than (300000);
set echo off
@q
@sql
set echo on
--
-- SHRINK
--
-- Probably fails...
alter table t2 shrink space deferred invalidation;
set echo off
@sql


@tab
prompt Get rid of indexes...
set echo on
drop index t1i;
drop index t2i;
set echo off
@q
@sql
set echo on
--
-- ADD CONSTRAINT
--
-- ## NOTE Accepted but might not be implemeted.
alter table t1 add constraint mypk1 primary key (id) deferred invalidation;
alter table t2 add constraint mypk2 primary key (id) deferred invalidation;
set echo off
@sql
set echo on
-- ## NOTE Accepted but not not be implemeted.
alter table t1 drop constraint mypk1 deferred invalidation;

set echo off

@tab
prompt rename
set echo on
drop index t1i;
drop index t2i;
set echo off
@q
@sql
set echo on
alter table t2 rename partition p2 to p2x deferred invalidation;
set echo off
@sql
set echo on

@tab
prompt rename
set echo on
drop index t1i;
drop index t2i;
set echo off
@q
@sql
set echo on
alter table t2 modify partition p2 read only deferred invalidation;
set echo off
@sql
set echo on

@tab
prompt rename
set echo on
drop index t1i;
drop index t2i;
set echo off
@q
@sql
set echo on
alter table t1 parallel 4 deferred invalidation;
alter table t2 parallel 4 deferred invalidation;
set echo off
@sql
set echo on

@tab
prompt rename
set echo on
drop index t1i;
drop index t2i;
set echo off
@q
@sql
set echo on
alter table t1 read only deferred invalidation;
alter table t2 read only deferred invalidation;
set echo off
@sql
set echo on

@tab
prompt rename
set echo on
drop index t1i;
drop index t2i;
set echo off
@q
@sql
set echo on
alter table t2 modify default attributes tablespace system deferred invalidation;
set echo off
@sql
set echo on
