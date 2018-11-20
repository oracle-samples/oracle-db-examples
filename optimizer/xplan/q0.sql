--
-- A simple query with a filter
--
select e.ename as "Employee Name"
from   employees        e
where  e.etype = 1;

@@all

--
-- A simple query with a filter with index
--
select e.ename as "Employee Name"
from   employees        e
where  e.id <= 1;

@@all


