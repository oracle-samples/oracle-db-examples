This demo shows you how you can use SQL plan management (SPM) to fix a SQL statement that is experiencing a performance regression caused by a sub-optimal plan.

SPM will search for historic plans, choose the best one and enforce it with a SQL plan baseline.

This demonstration is intended for use in Oracle Database 18c onwards. The primary script is "spm.sql", which demonstrates how to use SPM to find and implement a better plan.

Create the user, create the tables and then run "example.sql". It works as follows:

- Tables T1 and T2 have data skew
- Q1 is a query that joins T1 and T2
- Histograms tell the optimizer about the skew so Q1 performs well
- We drop the histograms and this induces a poor plan for Q1
- SPM is initiated and it finds the previous good plan
- The good plan is tested (automatically) by SPM and a SQL plan baseline is created
- Q1 now uses the good plan!

```
$ sqlplus / as sysdba     [or connect to PDB ADMIN]
SQL> @@user
SQL> connect spmdemo/spmdemo
-- 
-- Create test tables
-- 
SQL> @@tab
--
-- Review/execute the following script
--
SQL> @@example
```

Note that AWR is accessed. Check the Oracle Database License Guide for details.

The test creates two tables T1 and T2 - use a test database

DISCLAIMER:
   <br/>-- These scripts are provided for educational purposes only.
   <br/>-- They are NOT supported by Oracle World Wide Technical Support.
   <br/>-- The scripts have been tested and they appear to work as intended.
   <br/>-- You should always run scripts on a test instance.


