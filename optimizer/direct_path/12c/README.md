<h2>Direct Path Load Examples for Oracle Database 12c</h2>

These scripts are intended for Oracle Database release 12.1.0.2 and above.

The LST files examples were created on a 2-node RAC cluster. The number of nodes in your cluster will affect the final number of extents listed in your tsm_v_tsmhwmb.lst file, so expect your results to be different. If you are using a large RAC cluster, it is possible to get a similar number of extents created in the 12c example as the 11g example at lower DOP, but if you increase the DOP so that there is more that one PX server per database instance, then the the 12c case will "beat" the 11g case.

The SQL execution plans may not be displayed correctly on 12.1.0.1 and space management plan decorations will not be shown either.
