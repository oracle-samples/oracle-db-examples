# Copying Histogram and Extended Stats Definitions

If you have a pre-upgrade database or a test database and you want to duplicate extended stats and histogram definitions in another database or schema, these scrips show you how.

### copy_hist.sql

This script queries a schema to discover what histograms are present. It generates a set of DBMS_STATS.SET_TABLE_PREFS commands to match these histograms so you can explicitly define an equivalent set of histograms on another database. Like this:

```sql
exec dbms_stats.set_table_prefs('HR','REGIONS','METHOD_OPT','FOR ALL COLUMNS SIZE 1, FOR COLUMNS REGION_NAME SIZE 254')
exec dbms_stats.set_table_prefs('HR','CUSTOMERS','METHOD_OPT','FOR ALL COLUMNS SIZE 1, FOR COLUMNS CUST_TYPE SIZE 254')
```

Once the histograms are captured, the generated script can be executed on the relevat database to ensure that a consistent set of histograms are created until you choose to implement "FOR ALL COLUMNS SIZE AUTO".

Log into a DBA account in SQL plus and run the script. You will be asked to choose a schema to "capture". A file (gen_copy_hist.sql) will be spooled containing commands to create the same set of histograms on another database. 

### copy_hist_a.sql

This script queries a schema to discover what histograms are present. It generates a set of DBMS_STATS.SET_TABLE_PREFS commands to match these histograms so you can explicitly define a set of histograms on another database, but also leaves scope for the Oracle Database to discover and create new histograms where needed. Like this:

```sql
exec dbms_stats.set_table_prefs('HR','REGIONS','METHOD_OPT','FOR ALL COLUMNS SIZE AUTO, FOR COLUMNS REGION_NAME SIZE 254')
exec dbms_stats.set_table_prefs('HR','CUSTOMERS','METHOD_OPT','FOR ALL COLUMNS SIZE AUTO, FOR COLUMNS CUST_TYPE SIZE 254')
```

Once the histograms are captured, the generated script can be executed on the relevant database to ensure that a consistent set of histograms are created.

Log into a DBA account in SQL plus and run the script. You will be asked to choose a schema to "capture". A file (gen_copy_hist_a.sql) will be spooled containing commands to create the same set of histograms on another database. 

### copy_ext.sql 

This script is similar to the one above except that it creates a matching set of extended statistics. It spools a file called gen_copy_ext.sql.

### DISCLAIMER

*  These scripts are provided for educational purposes only.
*  They are NOT supported by Oracle World Wide Technical Support.
*  The scripts have been tested and they appear to work as intended.
*  You should always run scripts on a test instance.

### WARNING

*  These scripts drop and create user accounts. For use on test databases. DBA access is required.
