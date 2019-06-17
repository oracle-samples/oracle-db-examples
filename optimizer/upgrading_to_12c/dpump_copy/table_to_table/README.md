# Copying Statistics

When you copy statistics from one database schema to another, you need to consider:

- Base statistics information for tables, columns and indexes (e.g. NUM_ROWS)
- Extended statistics
- Histograms
- Column usage information
- Individual table DBMS_STATS preferences
- SQL plan directives

In this directory is a self-contained example to create a schema "S1" with a full compliment of statistics on table "T1" and stale statistics on "T2". The Data Pump example copies statistical metadata from T1 to T2.

To run the example:

```
$ sqlplus / as sysdba
SQL> @user
SQL> @look          -- This lists statistics information and metadata before it has been copied to T2
SQL> exit
$ ./dp_copy         -- Using Data Pump to copy metadata from T1 to T2
$ sqlplus / as sysdba 
SQL> @look                   -- This lists statistics information and metadata after it has been copied to T2 - note index does not have copied stats
SQL> @gather_t2              -- Gather statistics on T2 - BUT NOTE that stats are locked!
SQL> @unlock
SQL> gather_t2               -- Gather now works
SQL> @look                   -- T2 stats are now fresh and notice how column usage metadata has kept the histogram
```

Example *lst* and *log* files are included so you can see the expected results.

The script outputs where generated using Oracle Database 19c

LIMITATIONS
 
-  Note that INDEX statistics are not remapped with "remap_table" in datapump. This means that index stats will not be copied from T1I to T2I. 
-  Datapump remap_table does not reliably transport base table and column stats from one table to another (and the results are verion dependent). Hence, it is recommended that you gather statistics on the target table after the metadata is copied (T2 in this example)


### DISCLAIMER

*  These scripts are provided for educational purposes only.
*  They are NOT supported by Oracle World Wide Technical Support.
*  The scripts have been tested and they appear to work as intended.
*  You should always run scripts on a test instance.

### WARNING

*  These scripts drop and create user accounts. For use on test databases. DBA access is required.
