This demonstrates patch for Bug# 22174392. Oracle Database 12.2.0.1 was used in the demonstration.

It improves the costing of FIRST ROWS type queries so that the optimizer makes better use of indexes to sort returned rows.

This is important for applications that return rows (in sorted order) to users that paginate through the result set.

Create the table with make_tab.sql

See scripts before.sql and after.sql - spooled 'lst' output files are provided.

Compare the cost in the before and after versions, and also compare the differences in the resulting plans. The costs in the *after* example (for FETCH FIRST) are much lower and compare favorably with the ROWNUM queries.

DISCLAIMER:
   <br/>-- These scripts are provided for educational purposes only.
   <br/>-- They are NOT supported by Oracle World Wide Technical Support.
   <br/>-- The scripts have been tested and they appear to work as intended.
   <br/>-- You should always run scripts on a test instance.
<br/>
WARNING:
   <br/>-- The scripts will drop a table called "T" - use on test database only

