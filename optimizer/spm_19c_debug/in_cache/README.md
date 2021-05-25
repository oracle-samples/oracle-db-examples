This directory contains an example of deugging a SQL plan baseline in Oracle Database 19c.

Note: these scripts use SQL performance analyzer. 

The scripts make it easy to check SQL statements in the cursor cache.

You can set up an example by running test_setup.sql in a DBA account. Be aware it will drop and create SQL plan baselines. A SQL ID is displayed at the end of the script. You can enter this SQL ID when you run the "spb" scripts.

In most cases, you can use spb_noex.sql - it explains the plan of the relevant SQL statement in the cursor cache.

Alternatively, if you want to test execute the SQL statement, use spb.sql instead.

### DISCLAIMER

*  These scripts are provided for educational purposes only.
*  They are NOT supported by Oracle World Wide Technical Support.
*  The scripts have been tested and they appear to work as intended.
*  You should always run scripts on a test instance.

### WARNING

*  These scripts drop and create SQL plan baselines. For use on test databases
*  You need a license to use SQL performance analyzer to use these scripts
*  Check the license user manual for your database version 
*  Oracle Database 19c: https://docs.oracle.com/en/database/oracle/oracle-database/19/dblic/
