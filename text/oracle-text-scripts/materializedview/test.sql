drop table mytab;
create table mytab(search1 varchar2(10),search2 varchar2(10));
insert into mytab (search1,search2) values ('text1','text2');
exec ctx_ddl.drop_preference('mystorage')
exec ctx_ddl.create_preference( 'mystorage', 'BASIC_STORAGE' )
exec ctx_ddl.set_attribute ( 'mystorage', 'STAGE_ITAB', 'true' )

CREATE MATERIALIZED VIEW LOG ON mytab WITH ROWID(search1,search2),COMMIT SCN INCLUDING NEW VALUES;

drop materialized view mymview;
CREATE MATERIALIZED VIEW mymview
REFRESH FAST WITH ROWID ON COMMIT
AS
SELECT  search1,search2 from mytab;
CREATE INDEX cdi1 ON mymview(search1)
INDEXTYPE IS CTXSYS.CONTEXT
PARAMETERS('storage     mystorage
          ');
CREATE INDEX cdi2 ON mymview
(search2)
INDEXTYPE IS CTXSYS.CONTEXT
PARAMETERS('storage     mystorage
           ');

rem updating

select pnd_index_name from ctx_user_pending;

update mytab set search1='text3';
commit;

select pnd_index_name from ctx_user_pending;

select count(*) from DR$CDI1$G;
select count(*) from DR$CDI2$G;
