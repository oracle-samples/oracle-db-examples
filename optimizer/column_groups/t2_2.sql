--
-- The estimated nnumber of rows is 100 - which is wrong
-- It should be 1000
--
spool t2_2
set echo on

select /* STS MY_TEST_QUERY 1 */ sum(b.n0),count(*)
from  tab_corr1 a, tab_corr2 b
where a.n1 = 1
and   a.n2 = 1
and   a.n1 = b.n1
and   a.n2 = b.n2;

@@plan

select /* STS MY_TEST_QUERY 2 */ sum(b.n0),count(*)
from  tab_corr2 b
where b.n1 = 2
and   b.n2 = 2;

@@plan

spool off
