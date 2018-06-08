How to gather statistics on individual tables, but only if statistics need to be gathered.

The scripts are designed to work in SQL Plus or SQLCL.

Spool files (.lst) are included so you can see the expected results.

nopart.sql is an example for non-partitioned environments

part.sql creates a partitioned table

### DISCLAIMER

*  These scripts are provided for educational purposes only.
*  They are NOT supported by Oracle World Wide Technical Support.
*  The scripts have been tested and they appear to work as intended.
*  You should always run scripts on a test instance.

### WARNING

*  These scripts drop and create tables. For use on test databases.
