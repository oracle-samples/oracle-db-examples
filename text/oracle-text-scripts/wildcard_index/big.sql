drop table docs;
create table docs (text varchar2(2000));

begin
  for i in 1..50010 loop
    insert into docs values ('hello'||i);
  end loop;
end;
/

exec ctx_ddl.drop_preference  ('wci_word')
exec ctx_ddl.create_preference('wci_word', 'BASIC_WORDLIST')
exec ctx_ddl.set_attribute    ('wci_word', 'WILDCARD_INDEX', 'T')

create index docsindex on docs(text)
indextype is ctxsys.context
parameters ('wordlist wci_word')
/

