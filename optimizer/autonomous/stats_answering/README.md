This example demonstrates the Statistics-Base Query Transformation - how optimizer statistics can be used to answer certain queries.

Create a test user using the *user.sql* script.

Run the enture example using the *example.sql* script.

See an example of expected output in *example.lst*.

Note that the performance characteristics of the queries will change if the *test_stats.sql* is executed more than once (depending on the server result cache, cursor cache and DML used on the fact table). Re-running the *make_fact.sql* will reset the test and yield the expected results.

### DISCLAIMER

*  These scripts are provided for educational purposes only.
*  They are NOT supported by Oracle World Wide Technical Support.
*  The scripts have been tested and they appear to work as intended.
*  You should always run scripts on a test instance.

### WARNING

*  These scripts drop and create tables. For use on test databases.
