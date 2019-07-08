alter system flush shared_pool;

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

REM We are going to put three alternative plans into AWR:
REM
REM BOB_PK - plan hash value 772239758
REM BOB_IDX - plan hash value 4251244305
REM BOB FULL - plan hash value 1006760864

EXEC DBMS_WORKLOAD_REPOSITORY.create_snapshot;

@@q

declare
  n pls_integer;
begin
  for i in 1..100000
  loop
     execute immediate 'select /* HELLO */ num from bob where id = 100' into n;
  end loop;
end;
/

EXEC DBMS_WORKLOAD_REPOSITORY.create_snapshot;

alter index bob_pk invisible;

@@q

declare
  n pls_integer;
begin
  for i in 1..200000
  loop
     execute immediate 'select /* HELLO */ num from bob where id = 100' into n;
  end loop;
end;
/

EXEC DBMS_WORKLOAD_REPOSITORY.create_snapshot;

alter index bob_pk visible;
alter index bob_idx visible;

select /* HELLO */ num from bob where id = 100;
