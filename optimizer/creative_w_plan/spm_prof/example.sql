set trims on
set linesize 1000
set pagesize 1000
set tab off
set echo on
--
-- Create the test table and fill it
-- with data that has a large range skew
-- so that cardinality estimate is wrong.
--
@tab
--
-- Drop any SQL profiles from a previous run
--
@drop
--
-- We're not going to spool the output of
-- our test query, but let's look instead 
-- at how many rows we will get.
--
select count(*) from sales WHERE sale_date >= trunc(sysdate);
--
-- See above: not many rows. An index access method is 
-- the best plan in this case but the skew will 
-- mean that we'll get a FULL scan.
--
pause Press <CR> to continue...
--
-- Run our test query
--
@q1
--
-- Get the SQL execution plan
--
@plan

--
-- See plan above - We get a FULL scan: the cardinality estimate is wrong
--
pause Press <CR> to continue...

--
-- Next, we will run the SQL tuning advisor for the query
--
pause Press <CR> to continue...
--
-- Run the SQL tuning advisor
--
@tune

--
-- run the SQL tuning advisor report
--
@report

--
-- See above: a SQL profile is recommended
--
pause Press <CR> to continue...

--
-- Accept the profile
--
@accept

--
-- See above: we have accepted the SQL profile 
--
pause Press <CR> to continue...

--
-- Run the query again
--
@q1

@plan
--
-- See plan above - we now get index access and the SQL profile is being used
--

pause Press <CR> to continue...

--
-- Check the SQL profile is being used
-- 
@sql
--
-- See above - SQL_PROFILE column is populated
--

pause Press <CR> to continue...

--
-- Let's create SQL plan baselines for any SQL statement using a SQL profile
-- and does not have a SQL plan baseline already
--
pause Press <CR> to continue...

@makeb

pause Press <CR> to continue...
--
-- The SQL plan baseline has been created
--

--
-- Run the query again and see if it is using the new plan baseline
--
@q1
@plan1
@q1
@plan
--
-- See plan above - we are using the SQL profile AND SQL plan baseline
--

pause Press <CR> to continue...

--
-- Let's check that we are using both the SQL profile AND plan baseline
--
@sql2

--
-- See above: SQL_PLAN_BASELINE and SQL_PROFILE are filled in
--
pause Press <CR> to continue...

--
-- Look at the baseline - notice there is only one
--
@base

pause Press <CR> to continue...

--
-- Let's disable SQL profiles where we have a SQL plan baseline
--
@disablep

pause Press <CR> to continue...

--
-- Run the query again
-- There's a new child so plan1.sql will fail
-- but when I run q1 plan.sql will work OK (otherwise it will glitch)
--

@q1
@plan1
@q1
@plan

--
-- Notice above that we are not using the SQL profile any more - just the SQL plan baseline
--
pause Press <CR> to continue...

--
-- Taking another look at the SQL plan baselines, we have a new one
-- Remember - the SQL Profile is not constraining the plan any more
-- so the original FULL scan plan has been "rediscovered" and stored
-- in the SQL plan history, but we are still using the index plan
-- because it is being enforeced by the SQL plan baseline
--
@show

pause Press <CR> to continue...

--
-- Let's see if evolution thinks that the FULL scan is better
--
@evo

--
-- The evolution report has established that the FULL plan is not the best plan
--
pause Press <CR> to continue..

--
-- Let's change the data in the table...
--
@change

pause Press <CR> to continue..

--
-- Evolution establises that the FULL table plan is now better....
--
@evo

--
-- See above: Evolution establises that the FULL table plan is now better
--
pause Press <CR> to continue...

--
-- The new FULL SQL plan baseline plan is now accepted
--
@base

pause Press <CR> to continue...

--
-- Let's check the plan is FULL 
--
@q1
@plan1
@q1
@plan
--
-- See above. The FULL plan is now appropriate and can be used.
--
