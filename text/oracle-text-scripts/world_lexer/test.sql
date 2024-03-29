drop table wltest;

create table wltest(text varchar2(2000));
insert into wltest values ('the quick brown fox jumps over the lazy dog');

exec ctx_ddl.drop_preference('wllex')
exec ctx_ddl.create_preference('wllex', 'WORLD_LEXER')

exec ctx_ddl.drop_preference('wlwl')
exec ctx_ddl.create_preference('wlwl', 'BASIC_WORDLIST')
exec ctx_ddl.set_attribute    ('wlwl', 'WILDCARD_INDEX', 'Y')

create index wlindex on wltest(text)
indextype is ctxsys.context
parameters ('lexer wllex wordlist wlwl')
/

select gram_text from DR$WLINDEX$KG;


