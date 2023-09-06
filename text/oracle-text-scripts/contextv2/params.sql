-- demonstrating the use of a PARAMETERS clause on JSON SEARCH index

drop table foo;

create table foo(bar varchar2(2000));

insert into foo values ('hello world');

exec ctx_ddl.drop_preference('mylexer')
exec ctx_ddl.create_preference('mylexer', 'BASIC_LEXER')
exec ctx_ddl.set_attribute('mylexer', 'PRINTJOINS', '_')

create search index fooindex on foo(bar) for json
parameters ('lexer mylexer memory 1g sync (every "freq=secondly;interval=1") search_on text');

select * from foo where contains (bar, 'near((hello,world),2)') > 0;

