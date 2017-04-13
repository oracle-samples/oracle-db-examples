<h2>Utility Scripts for Using SPM in Practice</h2>

dropu.sql
* Drop SQL plan baselines for a schema.

evo.sql
* List SQL plan baselines you might want to evolve.

evou.sql
* List SQL plan baselines you might want to evolve for a specific schema.

list.sql
* List SQL plan baselines by last_executed

listu.sql
* List SQL plan baselines by last_executed for a specific schema

noact.sql
* Identify SQL statements in the cursor cache that have a matching SQL plan baseline but the plan baseline is not accepted and enabled.

nomatch.sql
* Identify SQL statements in the cursor cache that have an active and enabled SQL plan baseline but the plan baseline is not being honored.

nomatchu.sql
* Same as nomatch.sql but for a specified schema.

plan.sql
* Display an execution plan.

spmhint.sql
* Show outline hints inside a SQL plan baseline.

top.sql
* Look for "top SQL" in the cursor cache not using a SQL plan baseline.

DISCLAIMER:
   <br/>-- These scripts are provided for educational purposes only.
   <br/>-- They are NOT supported by Oracle World Wide Technical Support.
   <br/>-- The scripts have been tested and they appear to work as intended.
   <br/>-- You should always run scripts on a test instance.

