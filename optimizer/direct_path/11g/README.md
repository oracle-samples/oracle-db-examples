<h2>Direct Path Load Examples for Oracle Database 11g</h2>

Unlike 12.1.0.2, the LOAD AS SELECT is not decorated with the load strategy. 

The SQL scripts demonstrate how this information can be retrieved from a 10053 trace. The "show_type.sh" shows how you can grep this information from the "TRC" trace files.

Compare "tsm_v_tsmhwmb.lst" here with the 12c example to see how there are fewer new extents created in 12c due to hybrid TSM/HWMB.
