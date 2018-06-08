<h2>Utility Scripts for Using SPM in Practice</h2>

The example.sql script will demonstrate the scripts in "util". You will need permission
to create an Oracle user "spmtest". The user is created for you, so be
sure to use a test environment when you experiment with this for the first time.

Example output is shown in example.lst. 

**See also the README in the util directory.**

*example.lst*

 * Flush shared pool
 * Create a user called SPMTEST
 * Call dropu.sql to drop SQL plan baselines for user SPMTEST
 * Create a table called TAB1
 * Create index on table and gather stats
 * Run a test query on TAB1 and capture the plan as a SQL plan baseline (from the cursor cache)
 * Display SQL plan baselines for SPMTEST using listu.sql
 * Display the SQL execution plan for the SQL plan baseline - it uses an index
 * Execute the test query again and notice that the SQL plan baseline is being used and the plan uses the index
 * Run nomatchu.sql and it identifies no "non-matching" SQL plan baselines for SPMTEST - all is well
 * Drop the index! This makes it impossible to use the SQL plan baseline because the plan relies on the index!
 * Run the test query again and notice that the plan is now a FULL table scan and the SQL plan baseline is NOT being honored (the SQL plan baseline is not shown in the plan "Notes" section).
 * We can take a look of the OUTLINES in the SQL plan baseline and you will see it attempts: //INDEX(@"SEL$1" "TAB1"@"SEL$1" ("TAB1"."ID"))// - but the index is gone.
 * Run nomatchu.sql and notice that it identifies the query that has an enabled and accepted plan but the SQL plan baseline is NOT being honored (SQL_PLAN_BASELINE is NULL)
 * Look at the SQL plan baselines (using listu.sql) and see that there is a new non-accepted plan in the SQL plan history
 * Run evou.sql to evolve the new plan (it's the FULl table scan plan)
 * Run the test query again and this time a SQL plan baseline is used (look at "Notes" section)
 * The script nomatchu.sql no longer identifies a SQL plan baseline not being honored. 

For background, check out https://blogs.oracle.com/optimizer/entry/how_to_use_sql_plan

DISCLAIMER:
   <br/>-- These scripts are provided for educational purposes only.
   <br/>-- They are NOT supported by Oracle World Wide Technical Support.
   <br/>-- The scripts have been tested and they appear to work as intended.
   <br/>-- You should always run scripts on a test instance.

