--
-- An execution plan with a join and filter
--
select /*+ gather_plan_statistics  */
       e.ename as "Employee Name",
       t.tname as "Task Name"
from   employees        e
       join tasks t on (t.emp_id = e.id)
where  e.etype = 1;

@@sta
