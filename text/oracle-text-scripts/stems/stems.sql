drop table foo;

create table foo(text varchar2(200));

insert into foo values ('the quick brown fox jumps over the lazy dog');

exec ctx_ddl.drop_preference  ('stem_lexer')
exec ctx_ddl.create_preference('stem_lexer', 'BASIC_LEXER')
exec ctx_ddl.set_attribute    ('stem_lexer', 'INDEX_STEMS', 'NONE')

create index fooindex on foo(text)
indextype is ctxsys.context
parameters ('lexer stem_lexer sync(on commit)');

column token_text format a30
select token_type, token_text from dr$fooindex$i;

select * from foo where contains (text, '$jumping') > 0;
