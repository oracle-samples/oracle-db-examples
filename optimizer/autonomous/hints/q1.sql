select sum(t1.num), sum(t2.num)
from   table1 t1
join table2 t2 on (t1.id = t2.id);

@plan
