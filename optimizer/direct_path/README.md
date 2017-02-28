<h2>Direct Path Load Examples</h2>

SQL scripts to compare direct path load in Oracle Database 11g Release 2 with Oracle Database 12c (12.1.0.2 and above).  They are primarily intended to demonstrate the new Hybrid TSM/HWMB load strategy in 12c - comparing this to the TSM strategy available in 11g. See the 11g and 12c "tsm_v_tsmhwmb.sql" scripts and their associated spool file "tsm_v_tsmhwmb.lst" to see the difference in behavior between these two database versions. In particular, compare the reduced number of table extents created in the 12c example than 11g by comparing the "tsm_v_tsmhwmb.lst" files.

The 12c directory contains a comprehensive set of examples demonstrating how the SQL execution plan is decorated with the chosen load strategy. 

The 11g directory contains a couple of examples for comparative purposes. 

Each SQL script has an associated LST file so you can see an example of the output without having to run them.

The scripts need to run in a TEST Oracle database account with priviledges to create tables. Ideally, use
the default USERS tablespace but note that the script outputs are sensitive to your tablespace and database storage characteristics, so your output may differ from the examples given.

DISCLAIMER:
   <br/>-- These scripts are provided for educational purposes only. 
   <br/>-- They are NOT supported by Oracle World Wide Technical Support.
   <br/>-- The scripts have been tested and they appear to work as intended.
   <br/>-- You should always run scripts on a test instance.
   <br/>-- Note that they will DROP tables when they are executed.


