set echo on

connect ctxsys/ctxsys@localhost/pdb1

exec ctx_thes.drop_thesaurus('TEXT_TAGS');

host ctxload -thes -name TEXT_TAGS -thescase y -file text_test.txt -user ctxsys/ctxsys@localhost/pdb1
host ctxkbtc -user ctxsys/ctxsys@localhost/pdb1 -name TEXT_TAGS -verbose

connect roger/roger@localhost/pdb1

begin
ctx_ddl.drop_preference('TEXT_TAGS_LEX');
end;
/

begin
ctx_ddl.create_preference('TEXT_TAGS_LEX', 'BASIC_LEXER');
ctx_ddl.set_attribute('TEXT_TAGS_LEX', 'INDEX_THEMES', 'YES');
ctx_ddl.set_attribute('TEXT_TAGS_LEX', 'PROVE_THEMES', 'NO');
end;
/

drop table text_tags purge;
create table text_tags (
	tag_name varchar2(20),
	tag_query varchar2(256)
);

insert into text_tags values('Database','about(Database)');
insert into text_tags values('Oracle','about(Oracle)');
insert into text_tags values('Oracle 11g','about(11g)');
commit;

create index text_tags_idx on text_tags(tag_query) indextype is ctxsys.ctxrule
	parameters('lexer TEXT_TAGS_LEX');

select tag_name from text_tags where matches(tag_query, 'I have a table or view that does not exist')>0;
select tag_name from text_tags where matches(tag_query, 'oracle text needs better documentation.')>0;
select tag_name from text_tags where matches(tag_query, 'oracle 11g text needs better documentation.')>0;
select tag_name from text_tags where matches(tag_query, '11g text needs better documentation.')>0;
select tag_name from text_tags where matches(tag_query, '11G text needs better documentation.')>0;
