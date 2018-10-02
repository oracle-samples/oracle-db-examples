drop table t purge;

create table t nologging as
select d.* from dba_objects d,
( select 1 from dual connect by level <= 10 )
where object_id is not null;

alter table t noparallel;

alter table t modify object_id not null;

create index ix on t ( object_id ) ;

exec dbms_stats.gather_table_stats(user,'t')
