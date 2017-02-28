<h2>Zone Map and Attribute Clustering Examples</h2>

<h3>Purpose</h3>


This tutorial covers Oracle Database 12c attribute clusters and zone maps, features designed to offer significant IO reduction for queries that would otherwise perform full table scans.

<h3>Time to Complete</h3>
Approximately 45 minutes.

<h3>Introduction</h3>

Attribute clustering is a table-level directive that clusters data in close physical proximity based on the content of certain columns. Storing data that logically belongs together in close physical proximity can greatly reduce the amount of data to be processed and can lead to better performance of certain queries in the workload.

A zone map is a independent access structure that can be built for a table. During table and index scans, zone maps enable you to prune disk blocks of a table and (potentially full partitions of a partitioned table) based on predicates on table columns. Zone maps do this by maintaining a list of minimum and maximum column values for each zone (or range) of blocks in a table. Zone maps do this for partitions and sub-partitions too. If columns with common attributes are clustered together, it becomes possible to minimize the number of zones that need to be scanned in order to find a particular predicate match. For this reason, the effectiveness of zone maps is improved if rows are clustered together using attribute clustering or if they are manually sorted on load (using, for example, an ETL process that includes a sort). Zone maps can be used with or without attribute clustering.

In contrast to traditional clustering methods, attribute clusters have the capability to cluster data in fact tables based on dimension table attribute values. This has wide application, but it is particularly useful in Data Warehousing, star schema environments. It is possible to reduce significantly the number of fact table blocks that need to be scanned during joins that filter on dimension attribute values, including dimension attribute value hierarchies. Zone maps can be used as an alternative to bitmap indexes.

<h3>Hardware and Software Requirements</h3>

- Oracle Database 12c
- Zone maps require Oracle Exadata

<h3>Prerequisites</h3>

- Have access to Oracle Database 12c with a sample ORCL database, the SYS user with SYSDBA privilege and OS authentication (so that you can execute the sqlplus / as sysdba command.)
- This example uses the USERS tablespace, included in Oracle  Database 12c. To demonstrate these features adequately, reasonably large tables are required so approximately 1GB is required in the USERS tablespace.
- Have downloaded and unzipped the 12c_aczm.zip file (which is in the files subdirectory of this tutorial) into a working directory.
- Navigate to your working directory and execute all files from that location.
- Execute the tutorial setup which creates the aczm12c user.


<h3>Assumptions</h3>

- This tutorial assumes that when you begin executing steps for a topic, you complete the entire topic before going to another one. 
- You can also re-execute the tutorial setup from step number one (01_setup12c.sql): it will drop the aczm12c user and all its objects and then recreates it.

<h3>Tutorial Overview</h3>

Note that the generated data used in the tutorial is pseudo-random so your query results will not match the example output exactly. A 16K block size was when creating the sample output so the database statistic values you see will reflect differences in proportion the block size you are using.

- Create a SALES_SOURCE fact (this is used as a source of data for the fact tables created later in this tutorial).
- Create two dimension tables: PRODUCTS and LOCATIONS. 
- Create a join attribute clustered table called SALES_AC, clustering it using product and location attribute values.
- For comparative purposes, create a non-attribute clustered table called SALES.
- Examine the behavior of index range scans on the attribute clustered fact table without using zone maps.
- Remove fact table indexes and observe IO pruning using zone maps.
- Create a partitioned table, SALES_P, and observe zone and partition pruning (for example, using predicates on columns that are not included in the partition key).
- Invalidating and refreshing zone maps.

<h3>Setup</h3>

Set up the tutorial by running the following scripts. These scripts do not form part of the tutorial, they create the database user and the source table data.

- 01_setup12c.sql
- 02_table_create.sql
- 03_dim_fill.sql
- 04_source_fill.sql

<h3>Attribute Clustering</h3>

Here, we will create a couple of fact tables. SALES will not have attribute clustering or a zone map. It will be used to compare against SALES_AC, which will have attribute clustering and/or zone maps.

- 05_create_fact.sql

Attribute clusters can be used without zone maps. By themselves, there is no scan IO pruning (other than via Exadata storage indexes). However, index range scans can benefit from improved performance where index columns match attribute cluster columns. 

In many cases, attribute clusters bring common data values together and make them local to one another. This can benefit compression ratios for row-based compression in particular.

- 06_ac_only.sql

<h3>Linear and Interleaved Zone Maps</h3>

An Oracle Exadata environment is required from this point onwards: zone maps are an Exadata-only feature.

- 07_zm_lin_inter.sql


<h3>Join and Index Pruning</h3>

- 08_zm_prune.sql

<h3>Zone Maps on Partitioned Tables</h3>

Zone maps keep partition-level information as well as zone-level information. This makes it possible to partition eliminate on columns that are not included in partition keys or even on dimension attribute values. The likelihood of partition elimination is dependent on the level of correlation between zone map column values and the values in the partition key column (or columns).

- 09_part_zm.sql

<h3>Zone Map Maintenance</h3>

Certain operations will invalidate zones. Maintenance operations are required to refresh zone maps.

Zone maps containing some stale zones can still be used by queries. Query data will continue to be returned as expected.

- 10_zm_maint.sql

