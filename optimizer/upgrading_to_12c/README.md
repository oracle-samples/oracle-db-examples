# The Optimizer and Upgrading to Oracle Database 12c

If you are upgrading to Oracle Database 12c, you need to be aware that the Oracle Optimizer stores certain metadata to support its adaptive features. This can affect the way a DBA manages statistics during testing and upgrade. Certain optimizer statistics are created in response to the optimizer metadata to improve cardinality estimates over time. Specifically, these are *histograms* (in response to column usage information) and *column group statistics* (in response to SQL plan directives).

You need to be aware of changes to optimizer statistics and metadata so that you can manage the optimizer successfully during an upgrade. 

You may need to:

*  Understand exactly what histograms and extended column group statistics are present in the database. Some may have been created automatically and (for databases that host complex and/or multiple applications) there can be a variety of strategies in use to maintain these entities.
*  Copy statistics from one database environment to another. For example, from pre-production to production. Even if these two environments have different data, it may be deemed beneficial to use the same histograms and column group statistics in production to those found to be useful in pre-production.
*  Copy histogram definitions from one database to another (or from one schema to another) so that you have a consistent set of statistics.
*  Copy extended statistic definitions from one database to another (or from one schema to another) so that you have a consistent set of statistics.
*  Reliably copy ALL relevant optimizer statistics from one database (or schema) to another.
*  Use a specific and consistent set of histograms for a period of time after an upgrade (i.e. use tailored *method_opt* settings rather METHOD_OPT=>'FOR ALL COLUMNS SIZE AUTO').

In the directories below are some *experimental* scripts to help you manage statistics. The aim here is for you to take and adapt them to you own needs. They are broken down into three categories:

### [show_stats](https://github.com/oracle/oracle-db-examples/blob/master/optimizer/upgrading_to_12c/show_stats)

These scripts demonstrate how to view extended statistics, histograms, SQL plan directives and column usage information. They also demonstrate how you can see which histograms and extended statistics have been created automatically.

### [duplicate](https://github.com/oracle/oracle-db-examples/blob/master/optimizer/upgrading_to_12c/duplicate)

These scripts query a database schema to spool scripts that can be used to create matching histograms and extended statistics on another database.

### [dpump_copy](https://github.com/oracle/oracle-db-examples/blob/master/optimizer/upgrading_to_12c/dpump_copy)

These scripts demonstrate how easy it is to use Data Pump to copy all relevant statistics from one database schema to another.

### Note

All of the scripts are designed to work with Oracle Database 12c Release 1. Expect further updates when a new Oracle Database release becomes available.

### DISCLAIMER

*  These scripts are provided for educational purposes only.
*  They are NOT supported by Oracle World Wide Technical Support.
*  The scripts have been tested and they appear to work as intended.
*  You should always run scripts on a test instance.

### WARNING

*  These scripts drop and create user accounts. For use on test databases. DBA access is required.
