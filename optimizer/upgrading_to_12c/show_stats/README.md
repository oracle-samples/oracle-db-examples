# Viewing Statistics

If you have a pre-upgrade database or a test database and you want to duplicate extended stats and histogram definitions in another database or schema, these scrips show you how.

These scripts allow you to view various optimizer statistics and metadata:

### show_ext.sql

Lists extended statistics created manually and those created by the system in response to SQL plan directives.

### show_spd.sql

Lists SQL plan directives relevant to a specific schema.

### show_usage.sql

Lists column usage information. This metadata is generated automatically by the optimizer, so it is important that you have data here that is representative of your workload because it is used by DBMS_STATS.GATHER... to figure out where histograms might be needed (and *not* needed). You can use this script to get an idea of what data is present for a specific schema.

### show_hist.sql

Lists histograms present for a specific schema. It also looks at historical gather stats information to help you understand what initiated the creation of the histogram. For example, if METHOD_OPT was "FOR ALL COLUMNS SIZE AUTO" then it means that the histogram was created automatically in response to skew and column usage information. A simplified 11g version of the script is provided (show_hist_11g.sql) without METHOD_OPT information because this was not available in this release.

### DISCLAIMER

*  These scripts are provided for educational purposes only.
*  They are NOT supported by Oracle World Wide Technical Support.
*  The scripts have been tested and they appear to work as intended.
*  You should always run scripts on a test instance.

### WARNING

*  These scripts drop and create user accounts. For use on test databases. DBA access is required.
