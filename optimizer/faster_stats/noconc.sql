--
-- Disable concurrent stats collection
--
@cadm

exec dbms_stats.set_global_prefs('CONCURRENT','OFF')

select dbms_stats.get_prefs('CONCURRENT') from dual;

