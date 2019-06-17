# Copying Statistics

When you copy statistics from one database schema to another, you need to consider:

- Base statistics information for tables and indexes (e.g. NUM_ROWS)
- Extended statistics
- Histograms
- Column usage information
- Individual table DBMS_STATS preferences
- SQL plan directives

Luckily it is very easy to use Data Pump to achieve this aim. In this directory is a self-contained example to create a schema "S1" with a full compliment of statistics and a schema "S2" with nothing but index statistics. The Data Pump example copies all statistic and metadata from S1 to S2.

To run the example:

```
$ sqlplus / as sysdba
SQL> @users
SQL> @look          -- This lists statistics information and metadata before it has been copied to S2
SQL> exit
$ ./dp_copy         -- Using Data Pump to copy all relevant metadata from S1 to S2
$ sqlplus / as sysdba 
SQL> @look                   -- This lists statistics information and metadata after it has been copied to S2
SQL> @gather_s2.sql          -- S2 has a slightly different row count to S1, so this is corrected when stats are regathered.
                             -- The relevant histograms, extended statistics, SQL plan directives and so on are retained.
```                             
Example *lst* and *log* files are included so you can see the expected results.

Notice how all of the statistics and metadata is copied across from S1 to S2.

See directory "table_to_table" for copying statistics metadata from one table to another.

### DISCLAIMER

*  These scripts are provided for educational purposes only.
*  They are NOT supported by Oracle World Wide Technical Support.
*  The scripts have been tested and they appear to work as intended.
*  You should always run scripts on a test instance.

### WARNING

*  These scripts drop and create user accounts. For use on test databases. DBA access is required.
