--
-- An execution plan with a hash join
--
select e.ename as "Employee Name",
       t.tname as "Task Name"
from   employees        e
       join tasks t on (e.id = t.emp_id);

@@typ
