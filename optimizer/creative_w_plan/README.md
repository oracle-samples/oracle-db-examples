# Examples of how you can use SQL patch, SQL profiles and SQL plan baselines 

The base scrips have been tested on Oracle Database 12c Release 1 and Database 11g Release 2

Additional scripts have been provided for Oracle Database 12c Release 2

The script directories are:
* patch - to demonstrate SQL Patch (including how you can copy hints from one query and apply to another)
* profile - demonstrates how to create a SQL profile
* spm_plan - how to map the plan of one query against a different query (to resolve query regressions without changing application code)
* spm_profile - how to find a better plan with SQL tuning advisor and then create a SQL plan baseline for the improved plan so that the SQL profile can be replaced. Also demonstrates a SQL profile used with a SQL plan baseline.

### DISCLAIMER

*  These scripts are provided for educational purposes only.
*  They are NOT supported by Oracle World Wide Technical Support.
*  The scripts have been tested and they appear to work as intended.
*  You should always run scripts on a test instance.

### WARNING

*  These scripts drop and create tables. For use on test databases.
