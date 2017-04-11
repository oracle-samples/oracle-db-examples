# New synopses for Oracle Database Cloud Services (Oracle Database 12c Release 2)

These scripts are to support Part 3 of a 3-part blog post on incremental stats maintenance. Part 1 is here:

https://blogs.oracle.com/optimizer/entry/efficient_statistics_maintenance_for_partitioned

You will see how to create new-style synopses get an indication of their space and performance benefits.

A DBA account is required if you want to view synopses data in the data dictionary, otherwise, a non-DBA account is OK.

The "test" scripts show you the "nuts and bolts" of synopses and demonstrate performance benefits. The other numbered scripts demonstrate some of the different options for controlling synopses. The check.sql script shows you how to see what type of synopsis a partition has.

Script Descriptions...

01_mixed.sql
* It is possible to have a mixture of synopsis formats for an individual table...
* Create an incrementally managed, interval partitoned table T1 using old-style synopses
* Demonstrates how you can see that the partitions have ADAPTIVE SAMPLING synopses
* Make the last partition stale and add another partition
* Alter the table so that it uses new-style synopses
* Gather statistics on T1
* Observe that stats have been gathered on the new partiion and the previously stale partition
* The synopses on these two partitions are HyperLogLog

02_default.sql
* Demonstrate default behavior...
* Create an incrementally managed, interval partitoned table T1 using old-style synopses
* Demonstrates how you can see that the partitions have ADAPTIVE SAMPLING synopses
* Make the last partition stale and add another partition
* Set NDV algorithm to REPEAT OR HYPERLOGLOG
* Gather statistics
* All partitions remain ADAPTIVE SAMPLING (old-style)

03_hll.sql
* Demonstrate HYPERLOGLOG replacing old-style synopses immediately...
* Create an incrementally managed, interval partitoned table T1 using old-style synopses
* Add a new partition
* Demonstrates how you can see that the partitions have ADAPTIVE SAMPLING synopses
* Set NDV algorithm to HYPERLOGLOG
* Gather statistics
* ALL partitions are now HYPERLOGLOG

04_defaultmx.sql
* Demonstrate how tables with different synopsis type (to partitioned table) can be exchanged into table...
* Create an incrementally managed, interval partitoned table T1 using new-style synopses
* Create an load/exchange table called EXCH and create an old-style synopsis on the table
* Observer all partitions in T1 are HYPERLOGLOG
* Exchange partition P1 (in T1) with table EXCH
* Note that the synopsis on P1 is now ADAPTIVE SAMPLING and the other partitions are HYPERLOGLOG
* Add a new partition to T1
* Gather statistics on T1 and notice that new partition is HYPERLOGLOG but P1 remains ADAPTIVE SAMPLING because it is not stale and INCREMENTAL_STALENESS has a default value (allow mixed format).
* Make partition P1 stale
* Gather statistics
* Observe P1 is not HYPERLOGLOG
 
05_defaultmx.sql
* Default behavior is that ADAPTIVE SAMPLING synopsis partitioned table will keep these old-style synopses even if a HYPERLOGLOG table is exchanged in...
* Create an incrementally managed, interval partitoned table T1 using old-style synopses
* Create an load/exchange table called EXCH and create an new-style synopsis on the table
* After exchanging P1 with EXCH, P1 has HYPERLOGLOG synopses and the other partitions are ADAPTIVE SAMPLING
* Add a partition
* Gather statistics
* All partitions in T1 are ADAPTIVE SAMPLING
* Make P1 stale
* All partitions in T1 remain ADAPTIVE SAMPLING

06_defaultmx.sql
* Observer default REPEAT OR HYPERLOGLOG behavior for two partitions
* Create an incrementally managed, interval partitoned table T1 using old-style synopses - only two partitions
* Create an load/exchange table called EXCH and create an new-style synopsis on the table
* After exchanging P1 with EXCH, P1 has HYPERLOGLOG synopses and P2 is ADAPTIVE SAMPLING
* Add a partition
* Gather statistics
* ADAPTIVE SAMPLING synopses chosen

07_defaultmx.sql
* Similar to the previous example, only T1 is HYPERLOGLOG and EXCH is ADAPTIVE SAMPLING
* In this case, HYPERLOGLOG "wins" and when new partition is added and stats are re-gathered, all partitions are HYPERLOGLOG

08_nomix.sql
* Demonstrates what happens if INCREMENTAL_STALENESS is 'NULL' preventing mixed format
* Create an incrementally managed, interval partitoned table T1 using new-style synopses
* Create an load/exchange table called EXCH and create an old-style synopsis on the table
* After exchanging P1 with EXCH, P1 has ADAPTIVE SAMPLING synopses and P2 is HYPERLOGLOG
* Add a partition
* Gather statistics
* All partitions are now immediately HYPERLOGLOG because mixed format is "not allowed"

check.sql
* Demonstrates how you can see what synopses are on partitions

test1.sql
* This sets up a performance test
* Create a table T1 with a large number of partitions
* Create a load/exchange table called EXCH
* Set table prefs to incremental

test2.sql
* Set T1 synopses to HYPERLOGLOG
* Gather stats
* Take a look at the contents of the synopses tables
* Set T1 synopses to ADAPTIVE SAMPLING
* Gather stats
* Take a look at the contents of the synopses tables
* Perform a series of gather stats and not how long each takes - use this as baseline to see how long ADAPTIVE SAMPLING synopses take to create when compared with HYPERLOGLOG.
* Set T1 synopses to HYPERLOGLOG
* Perform a series of gather stats and not how long each takes - you should expect it to be faster than the ADAPTIVE SAMPLING example

test3.sql
* Take a look at exchange performance of HYPERLOGLOG vs ADAPTIVE SAMPLING
* Set T1 synopses to HYPERLOGLOG
* Perform a series of table exchange operations and observe how fast they are - then compare with test4.sql

test4.sql
* Take a look at exchange performance of HYPERLOGLOG vs ADAPTIVE SAMPLING
* Set T1 synopses to ADAPTIVE SAMPLING
* Perform a series of table exchange operations and observe how fast they are relatice to test3.sql
 

### Note

All of the scripts are designed to work with Oracle Database 12c Release 2.

### DISCLAIMER

*  These scripts are provided for educational purposes only.
*  They are NOT supported by Oracle World Wide Technical Support.
*  The scripts have been tested and they appear to work as intended.
*  You should always run scripts on a test instance.

### WARNING

*  These scripts drop and create tables. For use on test databases.
