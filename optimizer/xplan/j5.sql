--
-- Again forcing the (bad) nested loop join
-- Notice how the cost is more that j4.sql
-- because we are scanning a bigger table: TABLE_100000
--
-- Notice also that it is very clear that the "Cost" column
-- is PER START and not a total. There are some slight rounding errors.
--
select /*+ gather_plan_statistics use_nl(a b) */ sum(a.id), sum(b.id)
from   table_100         a
       join table_100000  b on (a.id = b.fkcol)
where  a.fcol <= 10;

@@sta

pause Press <cr> to continue

select /*+ gather_plan_statistics use_nl(a b) */ sum(a.id), sum(b.id)
from   table_100         a
       join table_100000  b on (a.id = b.fkcol)
where  a.fcol <= 20;

@@sta

pause Press <cr> to continue

select /*+ gather_plan_statistics use_nl(a b) */ sum(a.id), sum(b.id)
from   table_100         a
       join table_100000  b on (a.id = b.fkcol)
where  a.fcol <= 30;

@@sta

