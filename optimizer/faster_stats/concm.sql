--
-- Enable concurrent collection for auto optimizer stats collection
--
@cadm

exec dbms_stats.set_global_prefs('CONCURRENT','MANUAL')

select dbms_stats.get_prefs('CONCURRENT') from dual;

