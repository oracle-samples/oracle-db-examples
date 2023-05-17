This directory contains an example of deugging a SQL plan baseline in Oracle Database 19c.

To execute the spm.sql script you will need certain privileges. An example is included in user.sql

If you don't have a database you can use yourself, take a look at the spooled output in spm.lst

In particular, look at the "Hint Report" section towards the end of the file.

Additional scripts are available in the "in_cache" directory. These scripts us SQL performance analyzer to make it east to check SQL statements in the cursor cache, without the need to run them in SQL plus.

### DISCLAIMER

*  These scripts are provided for educational purposes only.
*  They are NOT supported by Oracle World Wide Technical Support.
*  The scripts have been tested and they appear to work as intended.
*  You should always run scripts on a test instance.

### WARNING

*  These scripts drop and create tables. For use on test databases
