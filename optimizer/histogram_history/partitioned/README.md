<h2>List history information for histograms associated with a partitioned table</h2>

This is a proof-of-concept script to list information on histogram changes over time for a given table. In particular, it reports: 

-  Changes to histogram bucket counts.
-  When histograms were added and removed for each table column.

The main script is "h_phist.sql". 

It requires a DBA account and you supply two parameters:

<pre>
SQL> @h_phist table_name user_name       [If the user_name is 'USER', the current username will be assumed]
</pre>

For a worked example, see spool file example.lst and a test script example.sql

WARNING: The example.sql script will drop a table called SALES. Always use test databases.

DISCLAIMER:
   <br/>-- These scripts are provided for educational purposes only.
   <br/>-- They are NOT supported by Oracle World Wide Technical Support.
   <br/>-- The scripts have been tested and they appear to work as intended.
   <br/>-- You should always run scripts on a test instance.

