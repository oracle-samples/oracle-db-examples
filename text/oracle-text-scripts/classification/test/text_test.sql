exec ctx_thes.drop_thesaurus('TEXT_TAGS');

begin
	ctx_thes.create_thesaurus('TEXT_TAGS', FALSE);
        ctx_thes.create_phrase   ('TEXT_TAGS','databases');
	ctx_thes.create_relation ('TEXT_TAGS','databases','NT','tables'); 
	ctx_thes.create_relation ('TEXT_TAGS','databases','NT','views'); 
end; 
/


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
--ctx_ddl.set_attribute('TEXT_TAGS_LEX', 'PROVE_THEMES', 'YES');
end;
/

drop table text_tags purge;
create table text_tags (
	tag_name varchar2(20),
	tag_query varchar2(256)
);

insert into text_tags values('Database','ABOUT(Database)');
insert into text_tags values('Database2','table or view');
insert into text_tags values('Oracle','ABOUT(Oracles)');
insert into text_tags values('Oracle 11g','ABOUT(11g)');
commit;

create index text_tags_idx on text_tags(tag_query) indextype is ctxsys.ctxrule
	parameters('lexer TEXT_TAGS_LEX');

set echo on
select tag_name from text_tags where matches(tag_query, 'I have a table or view which does not exist')>0;
select tag_name from text_tags where matches(tag_query, 'oracle text needs better documentation.')>0;
select tag_name from text_tags where matches(tag_query, 'oracle 11g text needs better documentation.')>0;
select tag_name from text_tags where matches(tag_query, '11g text needs better documentation.')>0;

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
