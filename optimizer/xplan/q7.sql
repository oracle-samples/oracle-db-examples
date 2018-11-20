--
-- Here is the actual plan for the NLJ example
-- I have removed the outline - and now it
-- uses NL join batching.
-- This is visible in the outline
--
select count(distinct e.ename),
       count(distinct t.tname)
from   employees        e
       join tasks t on (t.emp_id = e.id)
where  e.etype <= 5;

@@adv
