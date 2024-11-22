drop table t;

create table t (x varchar2(50));

insert into t values ('the jumper runs into hiding');

exec ctx_ddl.drop_preference  ('my_lex')
exec ctx_ddl.create_preference('my_lex', 'BASIC_LEXER')
-- exec ctx_ddl.set_attribute    ('my_lex', 'INDEX_STEMS', 'ENGLISH')

exec ctx_ddl.drop_preference  ('my_wrd')
exec ctx_ddl.create_preference('my_wrd', 'BASIC_WORDLIST')
-- exec ctx_ddl.set_attribute    ('my_wrd', 'STEMMER', 'ENGLISH')
-- exec ctx_ddl.set_attribute    ('my_wrd', 'STEMMER', 'FRENCH')
-- exec ctx_ddl.set_attribute    ('my_wrd', 'STEMMER', 'AUTO')

create index tx on t(x) indextype is ctxsys.context
parameters ('lexer my_lex wordlist my_wrd');

select token_type, token_text from dr$tx$i;

select * from t where contains(x, '$ran') > 0;



