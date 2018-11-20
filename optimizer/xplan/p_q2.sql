--
-- An execution plan with a join - partitioned example
--
select /*+ gather_plan_statistics */
       e.ename as "Employee Name",
       t.tname as "Task Name"
from   p_employees        e
       join p_tasks t on (t.emp_id = e.id);

@@sta
