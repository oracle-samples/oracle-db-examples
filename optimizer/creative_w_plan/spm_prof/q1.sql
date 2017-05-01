--
-- Run the query without displaying result set. Not using explain plan because I want the query to run.
-- Ignore the error message is raises
set termout off
select /* PROFTEST */ * from sales WHERE sale_date >= trunc(sysdate);
set termout on
