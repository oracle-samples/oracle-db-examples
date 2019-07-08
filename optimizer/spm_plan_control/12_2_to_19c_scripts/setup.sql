set echo on
alter system flush shared_pool;
exec dbms_stats.flush_database_monitoring_info

DECLARE
  l_plans_dropped  PLS_INTEGER;
BEGIN
  FOR REC IN (SELECT DISTINCT SQL_HANDLE FROM DBA_SQL_PLAN_BASELINES where sql_text like '%HELLO%')
  LOOP
      L_PLANS_DROPPED := DBMS_SPM.DROP_SQL_PLAN_BASELINE (
        sql_handle => rec.sql_handle,
        PLAN_NAME  => NULL);
  END LOOP;
END;
/

drop table bob purge;

create table bob (id number(10), id2 number(10), num number(10));
create unique index bob_pk on bob(id);
create index bob_idx on bob(id,id2);

begin
  for i in 1..1000
  loop
    insert into bob values (i,i,i);
  end loop;
end;
/
commit;

exec dbms_stats.gather_table_stats (ownname=>null,tabname=>'bob');
exec dbms_stats.flush_database_monitoring_info

--
-- This is the default plan
--
@@q
--
-- This is the plan we want (not a great idea - but it's a demo)
--
@@q2
