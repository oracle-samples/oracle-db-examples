--
-- Notice how the cost remains consistent - the cost
-- of each query is similar.
--
select /*+ gather_plan_statistics */ sum(a.id), sum(b.id)
from   table_100         a
       join table_1000   b on (a.id = b.fkcol)
where  a.fcol <= 10;

@@sta

pause Press <cr> to continue

select /*+ gather_plan_statistics */ sum(a.id), sum(b.id)
from   table_100         a
       join table_1000   b on (a.id = b.fkcol)
where  a.fcol <= 20;

@@sta

pause Press <cr> to continue

select /*+ gather_plan_statistics */ sum(a.id), sum(b.id)
from   table_100         a
       join table_1000   b on (a.id = b.fkcol)
where  a.fcol <= 30;

@@sta
