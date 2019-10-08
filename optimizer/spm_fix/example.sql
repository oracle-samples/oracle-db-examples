connect spmdemo/spmdemo
--
-- Drop existing SQL plan baselines to reset test
--
@@drop 
--
-- Observe the correct HASH JOIN plan because of data skew
--
@@q1 
--
-- Observe the correct NL JOIN plan for this predicate 
--
@@q2
--
-- Run the testq1 multiple times and capture in AWR
-- Assuming a SQL Disagnostics Pack licence.
--
-- We could also load Q1 into a SQL Tuning Set because
-- this source is also searched by SPM for previous plans.
-- SQL tuning sets required a SQL Tuning Pack licence.
--
@@q1many
--
-- Induce a bad plan for Q1 by dropping the histograms
-- so that the optimizer is no longer aware of skew
--
@@droph
--
-- Q1 now uses a NL JOIN, which in this case is bad because of data skew
-- The query has experienced a performance regression
--
@@q1
--
-- Now 'repair' the plan - SPM will find the better plan in AWR, 
-- test execute it and then create a SQL plan baseline to enforce it
--
-- Automatic SQL Plan management will look in AWR for resource-intensive
-- SQL so it is capable of finding our regressed plan automatically. 
--
-- But in this case, the DBA has to identify the long-running SQL statement 
-- by SQL ID and Plan Hash Value. However, once this has been done, SPM will
-- locate, test and apply the better plan automatically.
--
--
@@spm
--
-- Observe the HASH JOIN plan enforced by a SQL plan baseline
--
@@q1
--
-- The "pawr.sql" scipt is provided to purge AWR snapshots if
-- you want to run multiple tests and 'reset' AWR in between.
--
