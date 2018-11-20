--
-- Intro example 
--
select sum(a.id), sum(e.id)
from   table_10          a
       join table_100000 e on (a.id = e.id);

@@simple

select /*+ LEADING(@"SEL$58A6D7F6" "E"@"SEL$1" "A"@"SEL$1") */
       sum(a.id), sum(e.id)
from   table_10          a
       join table_100000 e on (a.id = e.id);

@@simple


