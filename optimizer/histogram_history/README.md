<h2>List history information for histograms associated with a table</h2>

This is a proof-of-concept script to list information on histogram changes over time for a chosen table. In particular, it reports: 

-  Changes to histogram bucket count.
-  When histograms were added and removed for each column.

The main script is "h_hist.sql". It requires a DBA account and you supply two parameters:

<pre>
SQL> @h_hist table_name user_name       [I the user_name is 'USER', the current username will be assumed]
</pre>

For a worked example, see example.lst and example.sql

WARNING: example.sql will issues a drop command for a table called SALES

DISCLAIMER:
   <br/>-- These scripts are provided for educational purposes only.
   <br/>-- They are NOT supported by Oracle World Wide Technical Support.
   <br/>-- The scripts have been tested and they appear to work as intended.
   <br/>-- You should always run scripts on a test instance.

