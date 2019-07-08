<h2>Using SQL Plan Management to Control SQL Execution Plans</h2>

Based on <a href="https://blogs.oracle.com/optimizer/using-sql-plan-management-to-control-sql-execution-plans">this blog article.</a>

The utility scripts are fix_all.sql and fix_spm.sql

They are intended to be similar in usage to the MOS script "coe_xfr_sql_profile.sql" - but using SQL plan baselines rather than SQL profiles.

You can run a simple testcase as follows:

```
$ sqlplus dbauser/password
SQL> @@setup
SQL> @@q                       --- The query will use the BOB_PK execution plan (this is the best one)
SQL> @@test_spm                --- This will force the query to use the BOB_IDX plan instead (not the best plan, but this is a demo!)
SQL> @@q                       --- See the query is now using the SQL plan baseline
SQL> @@look                    --- Take a look at the SQL plan baseline
```

If you are licensed, you can retireve plans from AWR or SQL tuining sets:

```
$ sqlplus dbauser/password
SQL> @@setup
SQL> @@awr                     --- Load two different plans in AWR for our SQL Statement [BOB_IDX and BOB_PK]
SQL> @@sts                     --- Load BOB FULL plan into a SQL tuning set
SQL> @@test_all                --- Pick one of the plans...
                               ---   BOB_PK        = plan hash value 772239758
                               ---   BOB_IDX       = plan hash value 4251244305
                               ---   BOB FULL scan = plan hash value 1006760864
SQL> @@q                       --- Run the query to see the plan you chose
SQL> @test_all                 --- Pick a different plan
SQL> @@q                       --- Take another look at the plan
SQL> @@look                    --- View SQL plan baselines
```

The scripts require Oracle Database 12c Release 2 onwards.

DISCLAIMER:
   <br/>-- These scripts are provided for educational purposes only.
   <br/>-- They are NOT supported by Oracle World Wide Technical Support.
   <br/>-- The scripts have been tested and they appear to work as intended.
   <br/>-- You should always run scripts on a test instance.
