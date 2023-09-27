drop table foo;
create table foo(txt varchar2(200));
insert into foo values ('école hôtelière');
exec ctx_ddl.drop_preference('lex')
exec ctx_ddl.create_preference('lex', 'WORLD_LEXER')
create index fooindex on foo(txt) indextype is ctxsys.context parameters('lexer lex');
select token_text from dr$fooindex$i;
