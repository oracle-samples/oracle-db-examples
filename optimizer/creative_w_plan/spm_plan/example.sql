set pagesize 1000
set linesize 1000
set trims on
set tab off
set echo on
--
-- Create the test table and fill it
-- with data that has a large range skew
-- so that cardinality estimate is wrong.
--
@tab
--
-- Drop any SQL plan baselines from a previous run
--
@drop
--
-- Run our test query
--
@q1

--
-- See plan above - We get a FULL scan: the cardinality estimate is wrong
--
pause Press <CR> to continue...

--
-- Let'srun a version of Q1 with a hint to give us the plan we
-- we want. Call this query "Q2".
--

pause Press <CR> to continue...

@q2


--
-- Q2 is similar to Q1 but there is a hint
-- We get the INDEX access method we want
--
pause Press <CR> to continue...


--
-- We are now going to "map" the query plan of Q2 
-- against Q1 so that Q1 will aquire the plan we want.
--

pause Press <CR> to continue...


--
-- Start by creating a SQL plan baseline for Q1
--
@makeb

pause Press <CR> to continue...

--
-- Check the baseline 
--
@base

pause Press <CR> to continue...

@q1
@plan1

@q1

--
-- See above Q1 now uses the SQL plan baseline, still a FULL scan
--
pause Press <CR> to continue...

--
-- Now disable the plan baseline
--
@dis

--
-- The SQL plan baseline is now disabled
--

pause Press <CR> to continue...

@base

--
-- Check disabled, above...
--
pause Press <CR> to continue...

@q1

--
-- Above, Q1 is no longer using the SQL plan baseline
--
pause Press <CR> to continue...

--
-- Locate Q2's plan hash value
--
@sql

pause Press <CR> to continue...

--
-- Check the baseline details
--
@base

pause Press <CR> to continue...

--
-- Now map the Q2 plan against Q1 SQL plan baseline
--
@map

pause Press <CR> to continue...

--
-- Now let's see if Q1 uses the SQL plan baseline and the INDEX now...
--

@q1
@plan1

@q1
--
-- Check above - see if Q1 uses the SQL plan baseline and the INDEX now...
--
