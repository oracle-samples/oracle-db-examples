--
-- For a given SQL ID, parse and create column groups
-- Parameters:
--    SQL ID
--    Table sample percentage
--    Y/N - Yes to create column groups immediately
--
set long 100000

--
-- Parse the relevant SQL statement
--
@@explain &1
--
-- Create the column groups
--
@@corr_from_plan &2 &3
