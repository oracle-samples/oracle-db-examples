# Introduction

How to detect the potential need for column groups (and create them automatically).

These scripts are aimed and detecting the need for column groups to support a specific query rather than an entire workload. Nevertheless, if a table has columns with correlated values, and a column group is created, then this has the potential to help many queries.

There are multiple approaches proposed here:

1. Use EXPLAIN PLAN to parse a test query while column usage seeding is enabled 
2. Use columnm usage seeding via a SQL tuning set
3. Query all rows (or a sample of rows) for a given table and look for column value correlations

# Overheads

Checking for column value correlation for a table by scanning rows can be time-consuming (the "corr" scripts). You should expect this approach to take a long time on large tables. The runtime can be reduced by sampling a proportion of table rows. For this reason, a sample size parameter is provided (it is a decimal value >0 and <100).

Column usage seeding has a small overhead and in some of the "cg" examples, a system-wide setting is used for a few seconds. Therefore, you should not use it on a production system running under high load. Also, bear in mind that scanning a large percentage of rows in a large table will have some overhead too (the "corr" scripts). For this reason, you may want to start with a small sample and build up.

# Demos

There are four demos:
<pre>
    SQL> -- Use column usage tracking to identify useful column groups
    SQL> @run_test1
    SQL> -- Scan tables and look for column value correlation
    SQL> @run_test2
    SQL> -- Use column usage tracking to identify useful column groups - for queries in a SQL tuning set
    SQL> @run_test3
    SQL> -- Introspect a SQL tuning set and scan the tables accessed ny the STS queries to look for column value correlations
    SQL> @run_test4
</pre>

It may be worth taking a closer look at "t4.sql" because it shows how you can "hide" statistics until you are ready to expose them to the workload. In this way you can make changes and test your queries before implementation. 

The demos make use of easy-to-use utility scripts. Here are some examples
<pre>
    SQL> -- Immediately create column groups that will benefit SQL ID "7kjpawwbyh1bz" (query must be in cursor cache) - uses column usage tracking
    SQL> @cg_from_sqlid 7kjpawwbyh1bz y
    SQL> -- Immediately create column groups for SQL statements in a SQL tuning set - uses column usage tracking
    SQL> @@cg_from_sts name_of_sql_tuning_set y
    SQL> -- Immediately create column groups that will benefit SQL ID "7kjpawwbyh1bz" by sampling 100% of rows in tables accessed by query. The query must be in cursor cache.
    SQL> @@corr_from_sqlid 7kjpawwbyh1bz 100 y
    SQL> -- Immediately create column groups for correlated columns on table current_user.TAB1 by sampling 10% of rows
    SQL> @@corr_from_table user tab1 10 y
    SQL> -- Immediately create column groups for correlated columns on tables accessed in the SQL tuning set "my_sql_tuning_set" - sample 10% of rows
    SQL> @@corr_from_sts my_sql_tuning_set 10 y
    SQL> -- Output a runnable SQL script that can be used to create column groups for correlated columns on tables accessed in the SQL tuning set "my_sql_tuning_set" - sample 50% of rows
    SQL> @@corr_from_sts my_sql_tuning_set 50 n
</pre>

# Limitations

The "sqlid" scripts rely on "execute immediate explain plan..." and this will not work for queries that exceed the maximum VARCHAR2 length. For cases like this, capture the relevant query in a SQL tuning set and then use the "sts" scripts provided. Check out "load_sqlset.sql" for an example.


# Disclaimer

   <br/>-- These scripts are provided for educational purposes only.
   <br/>-- They are NOT supported by Oracle World Wide Technical Support.
   <br/>-- The scripts have been tested and they appear to work as intended.
   <br/>-- You should always run scripts on a test instance.


