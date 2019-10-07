set timing on

select /*+ NO_ADAPTIVE_PLAN */ sum(t1.c), sum(t2.c)
from   t1, t2
where  t1.a = t2.a
and    t1.d = 1000;

@plan

