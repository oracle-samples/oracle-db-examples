select snap_id,to_char(begin_interval_time,'YYYY-DD-MM HH24:MI')
from   dba_hist_snapshot order by 1;

exec dbms_workload_repository.drop_snapshot_range(low_snap_id => &low, high_snap_id=>&hi);
