--
-- We need to gather statistcs on the column groups for them
-- to be useful. In this example, we are not going to publish
-- the newly gathered statistics so that only this session will
-- see them.
--
-- In this way we can test the effect of the column groups without
-- the workload using them, but note that this assumes that statistics are not
-- gathered and published on the relevant tables in another session.
--
-- Also, in real world examples, we need to be careful to restore the 
-- table preferences PUBLISH = TRUE
--
spool t4
set echo on

exec dbms_stats.set_table_prefs(user,'tab_corr1','publish','false')
exec dbms_stats.set_table_prefs(user,'tab_corr2','publish','false')
exec dbms_stats.gather_table_stats(user,'tab_corr1',no_invalidate=>false);
exec dbms_stats.gather_table_stats(user,'tab_corr2',no_invalidate=>false);

--
-- This query won't see the new statistics because they are not published
-- so the cardinality estimate will still be wrong (100)
--
select /* MY_TEST_QUERY */ sum(b.n0),count(*)
from  tab_corr1 a, tab_corr2 b
where a.n1 = 1
and   a.n2 = 1
and   a.n1 = b.n1
and   a.n2 = b.n2;

@@plan

--
-- Expose the next query to the column group statistics
-- and the cardinality estimate will be correct (1000)
--
alter session set OPTIMIZER_USE_PENDING_STATISTICS = TRUE;

select /* MY_TEST_QUERY */ sum(b.n0),count(*)
from  tab_corr1 a, tab_corr2 b
where a.n1 = 1
and   a.n2 = 1
and   a.n1 = b.n1
and   a.n2 = b.n2;

@@plan

--
-- Let's go ahead an publish
--
exec dbms_stats.publish_pending_stats(user,'tab_corr1')
exec dbms_stats.publish_pending_stats(user,'tab_corr2')
alter session set OPTIMIZER_USE_PENDING_STATISTICS = FALSE;
exec dbms_stats.set_table_prefs(user,'tab_corr1','publish','true')
exec dbms_stats.set_table_prefs(user,'tab_corr2','publish','true')

select /* PEND_FALSE MY_TEST_QUERY */ sum(b.n0),count(*)
from  tab_corr1 a, tab_corr2 b
where a.n1 = 1
and   a.n2 = 1
and   a.n1 = b.n1
and   a.n2 = b.n2;

@@plan
   
spool off
