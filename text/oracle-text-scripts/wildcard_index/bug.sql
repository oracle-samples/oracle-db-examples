drop table docs;
create table docs (text varchar2(2000));

insert into docs values ('test_joe_1');

exec ctx_ddl.drop_preference  ('wci_lex')
exec ctx_ddl.create_preference('wci_lex', 'BASIC_LEXER')
exec ctx_ddl.set_attribute    ('wci_lex', 'PRINTJOINS', '_')

exec ctx_ddl.drop_preference  ('wci_word')
exec ctx_ddl.create_preference('wci_word', 'BASIC_WORDLIST')
exec ctx_ddl.set_attribute    ('wci_word', 'WILDCARD_INDEX', 'T')
exec ctx_ddl.set_attribute    ('wci_word', 'WILDCARD_INDEX_K', '3')

create index docsindex on docs(text)
indextype is ctxsys.context
parameters ('wordlist wci_word lexer wci_lex')
/

select * from docs where contains(text, '%test\_joe%') > 0;
select * from docs where contains(text, '%test\_joe\_%') > 0;
