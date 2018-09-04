<h2>Using SQL Plan Management to Control SQL Execution Plans in Standard Edition</h2>

Based on <a href="https://blogs.oracle.com/optimizer/using-sql-plan-management-to-control-sql-execution-plans">this blog article.</a>

The example_se.sql calls "proc_se.sql" (proc_se.sql is essentially the same as ../proc2.sql)

Scripts create utility procedure called "add_my_plan" (see proc_se.sql) that allows you to take a SQL execution plan from a test query and apply it to an application query.

Example output is shown in example_se.lst. 

Note that example_se.sql creates a new user called SPM_TESTU.

Scripts tested in Oracle Database 18c Standard Edition

DISCLAIMER:
   <br/>-- These scripts are provided for educational purposes only.
   <br/>-- They are NOT supported by Oracle World Wide Technical Support.
   <br/>-- The scripts have been tested and they appear to work as intended.
   <br/>-- You should always run scripts on a test instance.

