--
-- The estimated nnumber of rows is 100 - which is wrong
-- It should be 1000
--
spool t2
set echo on

select /* MY_TEST_QUERY */ sum(b.n0),count(*)
from  tab_corr1 a, tab_corr2 b
where a.n1 = 1
and   a.n2 = 1
and   a.n1 = b.n1
and   a.n2 = b.n2;

@@plan
   
spool off
