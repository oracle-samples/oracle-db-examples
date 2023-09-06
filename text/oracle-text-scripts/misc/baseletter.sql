drop table t;
create table t (x varchar2(50));

insert into t values ('There is a Caf� in M�nchen');
insert into t values ('There is a Caf� in Munchen');

exec ctx_ddl.drop_preference('mylexer')
exec ctx_ddl.create_preference('mylexer', 'basic_lexer')

exec ctx_ddl.set_attribute('mylexer', 'base_letter', 'true')
exec ctx_ddl.set_attribute('mylexer', 'alternate_spelling', 'GERMAN')

create index ti on t(x) indextype is ctxsys.context
parameters('lexer mylexer');

set echo on

select * from t;
select token_text from dr$ti$i;

select x from t where contains (x, 'muenchen') > 0;
select x from t where contains (x, 'munchen') > 0;
select x from t where contains (x, 'm�nchen') > 0;
