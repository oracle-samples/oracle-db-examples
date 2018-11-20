--
-- A hash join plan with statistics
-- TASKS is filtered and is on the
-- left hand side of hash join.
--
select /*+ gather_plan_statistics  */
       e.ename as "Employee Name",
       t.tname as "Task Name"
from   employees        e
       join tasks t on (t.emp_id = e.id)
where  t.ttype <= 50;

@@sta
