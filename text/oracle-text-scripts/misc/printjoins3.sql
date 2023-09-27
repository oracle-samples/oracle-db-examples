drop table t;

create table t (c varchar2(200));

insert into t values ('a b c d e');

exec ctx_ddl.drop_stoplist('stop')
exec ctx_ddl.create_stoplist('stop', 'BASIC_STOPLIST')
exec ctx_ddl.add_stopword('stop', 'C');

create index i on t(c) indextype is ctxsys.context;

select * from t where contains( c, 'near((b, c d), 0)') > 0;
