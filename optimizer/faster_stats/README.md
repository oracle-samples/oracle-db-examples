

First, create a user called STEST by adapting the the user.sql script to use an appropriate tablespace (which needs to have about 1.5GB free).

Two 'connect' scripts are available:
cadm.sql      <-- Connects to SYSDBA account
cusr.sql      <-- Connects to the STEST user account
You can edit these to suit you system, particularly if you are using a multitenant environment.

Create tables: 
@tabs.sql

Gather database stats to start with a 'clean slate': 
@gather.sql

Make RM plan: 
@make_plan.sql 
Note that SCOPE=MEMORY so the plan change is temporary.
If necessary, you can drop the plan with drop_plan.sql

If you want to use the DEFAULT_MAINTENANCE_PLAN instead, 
run modify_plan.sql in the 'DEFAULT' directory.

To use AUTO_DEGREE: @auto.sql
To use serial execution: @noauto.sql

To user CONCURRENT: @conc.sql
To disable CONCURRENT: @noconc.sql

Prepare the test by dripping stats on the test tables: 
@drop_stats.sql

Initiate stats gathering by creating a 20min batch window: 
@run_gather.sql
If you want to use DEFAULT_MAINTENANCE_PLAN, then run 'run_gather.sql' in
the 'DEFAULT' subdirectory instead.

I have put the monitoring queries I use in util.sql 
Take a look at scheduler information: get_status.sql
Take a look at stale objects: stale.sql

If you want to stop the test: drop_window.sql  [stop.sql is an alternative]

========================

You can run a manual stats gathering with 'manual.sql'
