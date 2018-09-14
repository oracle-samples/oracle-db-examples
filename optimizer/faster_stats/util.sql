--
-- Looking for RM PX control and downgrades
--
select req_degree||'->'||degree,count(distinct qcsid) "value"
from   gv$px_session
where  req_degree is not null
group  by req_degree||'->'||degree;

--
-- PX Status
--
select status,count(*) "value"
from   gv$px_process
group by status;

--
-- Execs on consumer groups
--
select RESOURCE_CONSUMER_GROUP,nvl(count(*),0) "value"
from   gv$session s
where  service_name != 'SYS$BACKGROUND'
and    command != 0
and    type = 'USER'
and    program not like '%(P%'
group by RESOURCE_CONSUMER_GROUP;
