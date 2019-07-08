set echo on
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

alter session set OPTIMIZER_CAPTURE_SQL_PLAN_BASELINES=true;

select /* HELLO */ num from bob where id = 100;
select /* HELLO */ num from bob where id = 100;
select /* HELLO */ num from bob where id = 100;

alter index bob_pk invisible;
alter index bob_idx invisible;

select /* HELLO */ num from bob where id = 100;
select /* HELLO */ num from bob where id = 100;
select /* HELLO */ num from bob where id = 100;
select /* HELLO */ num from bob where id = 100;

alter session set OPTIMIZER_CAPTURE_SQL_PLAN_BASELINES=false;

alter index bob_pk visible;
alter index bob_idx visible;

select /* HELLO */ num from bob where id = 100;
@plana

select /*+ INDEX(bob bob_idx) */ /* HELLO */ num from bob where id = 100;
@plana

select sql_handle,sql_text,accepted,enabled from dba_sql_plan_baselines where sql_text like '%HELLO%';

break on sql_id
select sql_id,child_number,plan_hash_value,substr(sql_text,1,80) txt from v$sql where sql_text like '%bob where id ='||' 100'
order by 1,2;
