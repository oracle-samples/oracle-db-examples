<h2>List history information for histograms associated with a table</h2>

This is a proof-of-concept script to list information on histogram changes over time for a given table. In particular, it reports: 

-  Changes to histogram bucket counts.
-  When histograms were added and removed for each table column.

The main script is "h_hist.sql". 

It requires a DBA account and you supply two parameters:

<pre>
SQL> @h_hist table_name user_name       [If the user_name is 'USER', the current username will be assumed]
</pre>

For a worked example, see spool file example.lst and a test script example.sql

The subdirectory "partitioned" includes a script for partitioned tables. This is brand new and might need further debugging. Currently I have not implemented anything for a subpartitioned table. 

WARNING: The example.sql script will drop a table called SALES. Always use test databases.

NOTE: The earliest release I've tested this is Oracle Database 12c Release 2 but Release 1 should be OK too

DISCLAIMER:
   <br/>-- These scripts are provided for educational purposes only.
   <br/>-- They are NOT supported by Oracle World Wide Technical Support.
   <br/>-- The scripts have been tested and they appear to work as intended.
   <br/>-- You should always run scripts on a test instance.

