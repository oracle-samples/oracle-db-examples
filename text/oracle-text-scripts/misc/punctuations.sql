drop table foo;

create table foo (bar varchar2(2000));

insert into foo values ('the semicolon is rarely used correctly; it is more often used wrongly');

exec ctx_ddl.create_preference('myplexer', 'basic_lexer')
exec ctx_ddl.set_attribute('myplexer', 'punctuations', ';.?!')

exec ctx_ddl.create_section_group('foosection', 'basic_section_group')
exec ctx_ddl.add_special_section('foosection', 'sentence')

create index fooindex on foo(bar)
indextype is ctxsys.context
parameters ('lexer myplexer section group foosection');

select * from foo where contains (bar, '(rarely and wrongly) within sentence')> 0;
select * from foo where contains (bar, '(rarely and correctly) within sentence')> 0;
