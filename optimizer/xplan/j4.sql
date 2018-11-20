--
-- Now we are forcing a nested loop join. 
-- This is a bad choice because we will scan the entire TABLE_100000
-- for each row matched from TABLE_100
-- In this case, the cost will grow with each query (compare with j3.sql)
-- 
--
select /*+ gather_plan_statistics use_nl(a b) */ sum(a.id), sum(b.id)
from   table_100         a
       join table_10000  b on (a.id = b.fkcol)
where  a.fcol <= 10;

@@sta

pause Press <cr> to continue

select /*+ gather_plan_statistics use_nl(a b) */ sum(a.id), sum(b.id)
from   table_100         a
       join table_10000  b on (a.id = b.fkcol)
where  a.fcol <= 20;

@@sta

pause Press <cr> to continue

select /*+ gather_plan_statistics use_nl(a b) */ sum(a.id), sum(b.id)
from   table_100         a
       join table_10000  b on (a.id = b.fkcol)
where  a.fcol <= 30;

@@sta

