set echo on

exec ctx_thes.drop_thesaurus('TEXT_TAGS');

host ctxload -thes -name TEXT_TAGS -thescase y -file text_tags.txt -user ctxsys/ctxsys@localhost/pdb1

--accept junk prompt 'Compile thesaurus.  Hit return to continue.'
--run this
host ctxkbtc -user ctxsys/ctxsys@localhost/pdb1 -name TEXT_TAGS -verbose

begin
ctx_ddl.drop_preference('TEXT_TAGS_LEX');
end;
/

begin
   ctx_ddl.create_preference('TEXT_TAGS_LEX', 'BASIC_LEXER');
   ctx_ddl.set_attribute('TEXT_TAGS_LEX', 'INDEX_THEMES', 'YES');
   ctx_ddl.set_attribute('TEXT_TAGS_LEX', 'PROVE_THEMES', 'YES');
end;
/

drop table foo;
create table foo (id number primary key, text varchar2(2000));

insert into foo values(1, 'while processing information I have a table or view which does not exist');
--insert into foo values(2, 'oracle text needs better documentation.');
--insert into foo values(3, 'oracle 11g text needs better documentation.');
--insert into foo values(4, '11g text needs better documentation.');

create index fooindex on foo (text)
indextype is ctxsys.context
parameters('lexer text_tags_lex')
/

select token_text from dr$fooindex$i where token_type != 0;

drop table restab;

create table restab
     (query_id number, 
      theme varchar2(2000), 
      weight number);

exec ctx_doc.themes('fooindex', '1', 'restab', 0, TRUE);

select theme from restab;

quit
