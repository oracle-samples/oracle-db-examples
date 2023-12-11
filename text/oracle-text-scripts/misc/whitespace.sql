drop table t;

create table t (x varchar2(2000));

exec ctx_ddl.drop_preference   ('mylex')
exec ctx_ddl.create_preference ('mylex', 'BASIC_LEXER')
exec ctx_ddl.set_attribute     ('mylex', 'WHITESPACE', 'y')

insert into t values ('abcydefyghi jkl');

create index ti on t(x) indextype is ctxsys.context
parameters('lexer mylex');

select token_text from dr$ti$i;
