--
-- Here's a manual version
--
@cadm
set echo on

@make_plan

exec dbms_stats.gather_database_stats()
