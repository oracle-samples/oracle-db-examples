<h2>Using SQL Plan Management to Control SQL Execution Plans</h2>

Note that some scripts will DROP AND CREATE a new user called SPM_TESTU.

EDIT the following scripts to set the SPM_TESTU password and connect strings:

- example.sql, example2.sql, connect_user.sql ./SE/example_outln.sql ./SE/example_se.sql ./SE/connect_user.sql

Based on <a href="https://blogs.oracle.com/optimizer/using-sql-plan-management-to-control-sql-execution-plans">this blog article.</a>

The example.sql script demonstrates how to control SQL execution plans using SQL plan management. 

The example2.sql calls "proc2.sql": it adds a NEW SQL plan baselines and loads all other plans disabled.

Edit connect_admin.sql, connect_user.sql to suit you environment (e.g. MT or non-MT).

Scripts create utility procedures called "set_my_plan" and "add_my_plan" (see proc.sql and proc2.sql) that allows you to take a SQL execution plan from a test query and apply it to an application query.

Example output is shown in example.lst and example2.lst. 

Scripts tested in Oracle Database 11g Release 2, Oracle Database 12c Release 2 and Oracle Database 18c. The only caveat is that in Oracle Database 11g DBMS_XPLAN sometimes returns ORA-01403, but the example still works.

Now included: SPM example for Oracle Database 18c Standard Edition (see SE directory)


DISCLAIMER:
   <br/>-- These scripts are provided for educational purposes only.
   <br/>-- They are NOT supported by Oracle World Wide Technical Support.
   <br/>-- The scripts have been tested and they appear to work as intended.
   <br/>-- You should always run scripts on a test instance.

