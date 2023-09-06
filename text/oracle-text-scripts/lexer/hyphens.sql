drop table foo;
create table foo (bar varchar2(60));

insert into foo values ('there is a layoff at half-time and again at full-time');

exec ctx_ddl.drop_preference  ('mylex')
exec ctx_ddl.create_preference('mylex', 'BASIC_LEXER')
-- exec ctx_ddl.set_attribute    ('mylex', 'PRINTJOINS', '-')

create index fooindex on foo(bar) indextype is ctxsys.context
parameters ('lexer mylex')
/

select bar from foo where contains(bar, 'NEAR((full\-time, layoff))') > 0;
select bar from foo where contains(bar, 'NEAR((full\-time=part\-time, layoff))') > 0;

select bar from foo where contains(bar, 'NEAR((full time, layoff))') > 0;
select bar from foo where contains(bar, 'NEAR((full time=part\-time, layoff))') > 0;

select bar from foo where contains(bar, 'NEAR((full, layoff))') > 0;
select bar from foo where contains(bar, 'NEAR((full=part, layoff))') > 0;
