--
-- For a given SQL ID, parse and create column groups
-- Parameters:
--    SQL ID
--    Y/N - where Y - create column groups immediately
--                N - spool a reation script to verify and run later
--
set long 100000

--
-- This assumes that the parse will complete within 10 seconds
--
exec dbms_stats.seed_col_usage(null,null,10)
exec dbms_lock.sleep(1)
--
-- Parse the relevant SQL statement
--
@@explain &1
--
-- Create the column groups
--
@@cg_from_plan &2
