--
-- Take the outline from q7.sql and apply it
-- to a plan that should be a HASH join and not
-- nested loop.
-- Compare the 'Consistent Gets' in this example.
-- In this case, there's not much difference in 
-- elapsed time, but getting the join wrong
-- can be very bad for large queries.
--
set autotrace on
set linesize 150
set trims on 
set tab off
set timing on

--
-- Default 'good' plan
--
select count(distinct e.ename),
       count(distinct t.tname)
from   employees        e
       join tasks t on (t.emp_id = e.id)
where  e.etype <= 200;

pause Press <cr> to continue

--
-- Force NL Join 'bad' plan
--
select 
  /*+
      BEGIN_OUTLINE_DATA
      IGNORE_OPTIM_EMBEDDED_HINTS
      OPTIMIZER_FEATURES_ENABLE('12.2.0.1')
      DB_VERSION('12.2.0.1')
      ALL_ROWS
      OUTLINE_LEAF(@"SEL$58A6D7F6")
      MERGE(@"SEL$1" >"SEL$2")
      OUTLINE(@"SEL$2")
      OUTLINE(@"SEL$1")
      FULL(@"SEL$58A6D7F6" "E"@"SEL$1")
      INDEX(@"SEL$58A6D7F6" "T"@"SEL$1" ("TASKS"."EMP_ID"))
      LEADING(@"SEL$58A6D7F6" "E"@"SEL$1" "T"@"SEL$1")
      USE_NL(@"SEL$58A6D7F6" "T"@"SEL$1")
      NLJ_BATCHING(@"SEL$58A6D7F6" "T"@"SEL$1")
      END_OUTLINE_DATA
  */
       count(distinct e.ename),
       count(distinct t.tname)
from   employees        e
       join tasks t on (t.emp_id = e.id)
where  e.etype <= 200;

set autotrace off

pause Press <cr> to continue

select
  /*+
      BEGIN_OUTLINE_DATA
         gather_plan_statistics
      IGNORE_OPTIM_EMBEDDED_HINTS
      OPTIMIZER_FEATURES_ENABLE('12.2.0.1')
      DB_VERSION('12.2.0.1')
      ALL_ROWS
      OUTLINE_LEAF(@"SEL$58A6D7F6")
      MERGE(@"SEL$1" >"SEL$2")
      OUTLINE(@"SEL$2")
      OUTLINE(@"SEL$1")
      FULL(@"SEL$58A6D7F6" "E"@"SEL$1")
      INDEX(@"SEL$58A6D7F6" "T"@"SEL$1" ("TASKS"."EMP_ID"))
      LEADING(@"SEL$58A6D7F6" "E"@"SEL$1" "T"@"SEL$1")
      USE_NL(@"SEL$58A6D7F6" "T"@"SEL$1")
      NLJ_BATCHING(@"SEL$58A6D7F6" "T"@"SEL$1")
      END_OUTLINE_DATA
  */
       count(distinct e.ename),
       count(distinct t.tname)
from   employees        e
       join tasks t on (t.emp_id = e.id)
where  e.etype <= 200;

@@sta
