# Partition Exchange Loading

These scripts are to support Part 2 of a 3-part blog post on partition echange loading. Part 1 is here:

https://blogs.oracle.com/optimizer/entry/efficient_statistics_maintenance_for_partitioned

They are primarily designed with Oracle Database 12c in mind but they will largely work in Oracle Database 11g - except that the steps to pre-create synopses will fail and the post-exchange stats gathering for the new partition cannot be avoided. 

### [example.sql](https://github.com/oracle/oracle-db-examples/blob/master/optimizer/partition_exchange_load/example.sql)

This script shows how partition exchange load interacts with incremental statistics for a subpartitioned main table.

### [list_s.sql](https://github.com/oracle/oracle-db-examples/blob/master/optimizer/partition_exchange_load/list_s.sql)

This script lists extended statistics and histograms for a paritioned table.

### [check_hist.sql](https://github.com/oracle/oracle-db-examples/blob/master/optimizer/partition_exchange_load/check_hist.sql)

This script compares histograms at the table level with histograms for each (sub)partition. This is not a problem and not uncommon if histograms are created automatically (using 'FOR ALL COLUMNS SIZE AUTO'). Nevertheless, it's useful to be aware of this if you have been managing histograms and partition statistics in an ad-hoc manner. It might not have been your intention.

### Note

All of the scripts are designed to work with Oracle Database 12c.

### DISCLAIMER

*  These scripts are provided for educational purposes only.
*  They are NOT supported by Oracle World Wide Technical Support.
*  The scripts have been tested and they appear to work as intended.
*  You should always run scripts on a test instance.

### WARNING

*  These scripts drop and create tables. For use on test databases.
