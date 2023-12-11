drop table t;
create table t(c varchar2(2000));
create search index i on t(c) parameters ('maintenance auto');
insert into t values ('hello world');
commit;
select * from t where contains (c, 'hello') > 0;
exec dbms_session.sleep(3)
select * from t where contains (c, 'hello') > 0;
