
-- drop.sql
-- Drop all the SQL patches used in this example.

-- look.sql
-- List all existing SQL patches and then all SQL statements in SQL area using them.

-- sql.sql
-- List SQL IDs for our test queries

-- Test 1
-- ======
@drop
--
-- Execute our test query
-- It uses an index
--
@q0
-- Exeute the same query, but this time
-- with a hint to make is FULL scan.
-- We'll take a look at the outline to
-- see what hint we can use to force the
-- first test query to use a FULL scan 
-- rather than the index.
@q0full
--
-- Let's patch the "q0.sql" query with
-- FULL(@"SEL$1" "TAB1"@"SEL$1") to make it
-- scan the table
-- You must use patchq0_122.sql if you are using 12.2.
--
@patchq0_122
--
-- Check to see if this query now uses the patch
-- and no longer uses the index...
--
@q0
@look
 
-- Test 2
-- ======
@drop
--
-- Execute our test query "q1"
-- It has a "stupid" USE_HASH hint
--
@q1
--
-- Let's stop it using the hint!
--
@patchq1_nohint_122
--
-- It now uses nested loop join...
--
@q1

-- Test 3
-- ======
@drop
-- 
-- Run q2 - and notice it uses index on TAB2 (TAB2TYI)
--
@q2
--
-- Take a look at "q3". It is the same as q2 but
-- it has a hint to give us a FULL scan on TAB2
--
@q3
--
-- It looks like we can use FULL(@"SEL$5DA710D3" "TAB2"@"SEL$2")
-- if we want to make q2 use the same plan.
-- Instead, let's just copy the whole outline from q3 and
-- apply to q2.
-- We can see the SQL_ID's we must use...
--
@sql
-- 
-- Now copy...
--
@copy_122
--
-- q2 now uses a FULL scan on TAB2
--
@q2
