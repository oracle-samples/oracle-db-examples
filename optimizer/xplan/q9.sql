--
-- An execution plan with a join
--
select e.ename as "Employee Name",
       t.tname as "Task Name"
from   employees        e
       join tasks t on (t.emp_id = e.id)
where  e.etype <= 5;

@@adv

pause Press <cr> to continue

select
  /*+
      gather_plan_statistics
  */
       e.ename as "Employee Name",
       t.tname as "Task Name"
from   employees        e
       join tasks t on (t.emp_id = e.id)
where  e.etype <= 5;

@@sta

pause Press <cr> to continue

select 
  /*+
      BEGIN_OUTLINE_DATA
      IGNORE_OPTIM_EMBEDDED_HINTS
      gather_plan_statistics
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
      NO_NLJ_BATCHING(@"SEL$58A6D7F6" "T"@"SEL$1")
      END_OUTLINE_DATA
  */
       e.ename as "Employee Name",
       t.tname as "Task Name"
from   employees        e
       join tasks t on (t.emp_id = e.id)
where  e.etype <= 5;

@@sta

