
select /*+ gather_plan_statistics use_nl(a b) */ sum(a.id), sum(b.id)
from   table_100         a
       join table_100000  b on (a.id = b.fkcol)
where  a.fcol <= 11;

@@sta

alter system flush shared_pool;

alter session set tracefile_identifier = 'EXAMPLE_TRACE';
alter session set events = '10053 trace name context forever, level 1';

select /*+ use_nl(a b) */ sum(a.id), sum(b.id)
from   table_100         a
       join table_100000  b on (a.id = b.fkcol)
where  a.fcol <= 11;

alter session set events = '10053 trace name context off';
