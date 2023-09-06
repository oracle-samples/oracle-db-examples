drop table foo;

create table foo(x varchar2(200));

insert into foo values ('The {quick} brown >fox< jump''s over the %lazy dog.');

exec ctx_ddl.drop_preference  ('mylex')
exec ctx_ddl.create_preference('mylex', 'BASIC_LEXER')
exec ctx_ddl.set_attribute    ('mylex', 'PRINTJOINS', '{}<>''%')
create index fooindex on foo(x) indextype is ctxsys.ctxcat
parameters ('lexer mylex');

-- see what tokens are indexed

select dr$token from DR$FOOINDEX$I;

select x from foo where catsearch(x, 'quick', null) > 0;

select x from foo where catsearch(x, '\{quick\}', null) > 0;

