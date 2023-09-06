set echo on
set autotrace off
set timing on
set time on

drop table t;
create table t (pk number, title varchar2(80), text varchar2(4000))
storage (initial 10M next 10M pctincrease 0 maxextents unlimited);

insert into t values (null, 'fox title',
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ' ||
'the quick brown fox jumps over the lazy dog ');

insert into t values (null, 'box title',
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ' ||
'the quick brown box jumps over the lazy dog ');

insert into t select * from t;
-- 4
insert into t select * from t;
-- 8
insert into t select * from t;
-- 16
insert into t select * from t;
-- 32
insert into t select * from t;
-- 64
insert into t select * from t;
-- 128
insert into t select * from t;
-- 256
insert into t select * from t;
-- 512
insert into t select * from t;
-- 1024
insert into t select * from t;
-- 2048
insert into t select * from t;
-- 4096
insert into t select * from t;
-- 8192
insert into t select * from t;
-- 16384
insert into t select * from t;
-- 32768
insert into t select * from t;
-- 65536
--insert into t select * from t;
-- 128K
--insert into t select * from t;
-- 256K
--insert into t select * from t;
-- 512K

select count(*) from t;

update t set pk = rownum;

create index t_btree on t(title);
create index t_domain on t(text) indextype is ctxsys.context;

--$ net stop OracleServiceORA817
--$ net start OracleServiceORA817
--connect roger/roger
--select count(*) from t where contains (text, 'fox') > 0;

--$ net stop OracleServiceORA817
--$ net start OracleServiceORA817
--connect roger/roger
--select pk       from t where title='fox title';

--$ net stop OracleServiceORA817
--$ net start OracleServiceORA817
--connect roger/roger
--select pk       from t where contains (text, 'fox') > 0;
