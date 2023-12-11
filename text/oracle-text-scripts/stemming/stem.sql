drop table t;

create table t (x varchar2(50));
insert into t values ('helloworld');

exec ctx_ddl.drop_preference('mylex')
exec ctx_ddl.create_preference('mylex', 'basic_lexer')
exec ctx_ddl.set_attribute('mylex', 'stem_index', 'yes')
