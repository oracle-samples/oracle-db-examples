<h2>SQL Plan Management Examples</h2>

Some scripts on the subject of SQL Plan Management in Oracle 11gR2. 

Spooled output in "lst" shows how the scripts can be used. 

View in order: 
* introduction.lst 
* evolve.lst
* sts.lst

introduction.lst
The basics of SQL plan management.
* Create SALES table
* Fill with data - the data is skewed
* Create index
* Gather stats
* Drop all SQL plan baselines to reset test
* Check cursor cache for queries LIKE "%sales%"
* Confirm there are no SQL plan baselines
* Execute a SALES query with a bind variable
* Check the query plan (it's a FULL table scan)
* Run SALES query again with a different bind variable value
* Check the plan - it's an INDEX RANGE SCAN because the data is skewed so use of an index is more efficient
* Run the query again, showing the other bind variable value results in a FULL scan.
* Repeat query, with different bind variable value resulting in INDEX RANGE SCAN
* Look in cursor cache - the query has multiple plans
* Use DISPLAY_CURSOR to see the different plans in the cursor cache
* Load all the plans from the cursor cache to create SQL plan baselines
* Check to see that the SQL plan baselines have been loaded
* Run the query with different bind variable values and confirm that both FULL and INDEX plans are used and the SQL plan baselines are used.
* Display the plan in a SQL plan baseline.

evolve.lst
Demonstrating evolution.
* Flush the shared pool to ensure that queries will be hard parsed
* Drop all baselines
* Run query with a bind variable value yielding a FULL scan (id=-1).
* Load the plan from the cursor cache to create a SQL plan baseline.
* Query DBA_SQL_PLAN_BASELINES to see the new plan baseline.
* Run the SALES query with a different bind variable value (id=1) - and because the data is skewed, it would be better if an index plan is used.
* However, note that the plan is still a FULL scan. This is because the SQL plan baseline is now being used and the only accepted plan is the FULL scan. The SQL plan baseline will prevent a new plan being used until it is accepted.
* Query DBA_SQL_PLAN_BASELINES and you can see that there is now an ACCEPTED=NO plan in the SQL plan history - in other words the INDEX plan has been seen but has not yet been accepted
* Run the SALES queries again
* EVOLVE SQL plan baselines using DBMS_SPM.EVOLVE_SQL_PLAN_BASELINE
* The new INDEX plan is accepted automatically
* Run the SALES query (with id=1) and it will now use the INDEX plan
* Run the SALES query (with id=-1) and it will now use the FULL plan

sts.sql

This example shows how you might use SQL plan management to capture ALL plans for a given workload. It means that you will capture and immediate enable all plans - so if there's data skew you won't need to be concerned that some important plans are not enabled. The idea here is that you capture the worload in a SQL tuning set, then you use this as the source of accepted SQL plan baselines.

* Flush the shared pool and drop SQL plan baselines
* Run a bunch of queries with different bind variable values and notice that one of the queries has a FULL plan and an INDEX plan (just as it did in evolve.lst)
* Look in the cursor cache
* Create a SQL tuning set from the cursor cache - note it assume that you are using a user called "ADHOC"
* Check the contents of the SQL tuning set
* Create SQL plan baselines from the SQL tuning set
* List the SQL plan baselines
* Run the SALES queries with different bind variable values and notice that the SQL plan baselines are used and the correct FULL or INDEX plan is immediately used where appropriate.


DISCLAIMER:
   <br/>-- These scripts are provided for educational purposes only.
   <br/>-- They are NOT supported by Oracle World Wide Technical Support.
   <br/>-- The scripts have been tested and they appear to work as intended.
   <br/>-- You should always run scripts on a test instance.
<br/>
WARNING:
   <br/>-- "drop.sql" will drop all SQL Plan Baselines
  

