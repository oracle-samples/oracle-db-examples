spool t6
set echo on
set feedback on

exec dbms_stats.gather_table_stats(user,'tab_corr1',no_invalidate=>false)
exec dbms_stats.gather_table_stats(user,'tab_corr2',no_invalidate=>false)

select /* MY_TEST_QUERY */ sum(b.n0),count(*)
from  tab_corr1 a, tab_corr2 b
where a.n1 = 1
and   a.n2 = 1
and   a.n1 = b.n1
and   a.n2 = b.n2;

exec dbms_stats.gather_table_stats(user,'tab_corr1',no_invalidate=>false)
exec dbms_stats.gather_table_stats(user,'tab_corr2',no_invalidate=>false)

--
-- Now we have column groups, the estimate should be 1000
--
select /* MY_TEST_QUERY */ sum(b.n0),count(*)
from  tab_corr1 a, tab_corr2 b
where a.n1 = 1
and   a.n2 = 1
and   a.n1 = b.n1
and   a.n2 = b.n2;

@@plan

spool off
