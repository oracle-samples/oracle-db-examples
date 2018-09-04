Demo for unpublished bug #27500184

In SE, cursor is repeatedly invalidated if a 
SQL plan baseline exists and a new plan
has been found by the optimizer.

Create a DBA user. E.g. adhoc/adhoc

Log in to DBA user.

Run make_tc.sql

Next:
@run
Then:
@run2

Spool files are included comparing the SE and EE runs.
