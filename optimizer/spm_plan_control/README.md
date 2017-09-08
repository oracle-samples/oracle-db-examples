<h2>Using SQL Plan Management to Control SQL Execution Plans</h2>

The example.sql script demonstrates how to control SQL execution plans using SQL plan management. 

It creates a utility procedure called "set_my_plan" (see proc.sql) that allows you to take a SQL execution plan from a test query and apply it to an application query.

Example output is shown in example.lst. 

Note that the example.sql script will create a new user called SPM_TESTU.

DISCLAIMER:
   <br/>-- These scripts are provided for educational purposes only.
   <br/>-- They are NOT supported by Oracle World Wide Technical Support.
   <br/>-- The scripts have been tested and they appear to work as intended.
   <br/>-- You should always run scripts on a test instance.

