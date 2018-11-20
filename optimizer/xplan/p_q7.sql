--
-- NL example
-- Without and then with partitioning
--
select /*+ gather_plan_statistics */
       count(distinct e.ename),
       count(distinct t.tname)
from   employees        e
       join tasks t on (t.emp_id = e.id)
where  e.etype <= 5;

@@sta

select /*+ gather_plan_statistics */
       count(distinct e.ename),
       count(distinct t.tname)
from   p_employees        e
       join p_tasks t on (t.emp_id = e.id)
where  e.etype <= 5;

@@sta
