conn ctxsys/ctxsys

exec ctx_thes.drop_thesaurus('TEXT_TAGS');

begin
    ctx_thes.create_thesaurus('TEXT_TAGS', TRUE);
    ctx_thes.create_relation('TEXT_TAGS','Database','USE','Database(DB)');
    ctx_thes.create_relation('TEXT_TAGS','Database','NT','table(DB)');
    ctx_thes.create_relation('TEXT_TAGS','Database','NT','view(DB)');

    ctx_thes.create_relation('TEXT_TAGS','Web','USE','Web(WEB)');
    ctx_thes.create_relation('TEXT_TAGS','Web','NT','table(WEB)');
    ctx_thes.create_relation('TEXT_TAGS','Web','NT','HTML(WEB)');
    ctx_thes.create_relation('TEXT_TAGS','Web','NT','CSS(WEB)');
end;

/


conn scott/tiger

exec ctx_ddl.drop_preference('TEXT_TAGS_LEX');

begin
    ctx_ddl.create_preference('TEXT_TAGS_LEX', 'BASIC_LEXER');
end;

/

drop table text_tags purge;
create table text_tags (
    tag_name varchar2(20),
    tag_query varchar2(256)
);

 
insert into text_tags values('Database','NT(Database,20,TEXT_TAGS)');
insert into text_tags values('Web Development','NT(Web,20,TEXT_TAGS)');

commit;

create index text_tags_idx on text_tags(tag_query) indextype is ctxsys.ctxrule
parameters('lexer TEXT_TAGS_LEX');

 
select tag_name from text_tags where matches(tag_query, 'How do I format my HTML table using CSS')>0;
select tag_name from text_tags where matches(tag_query, 'I have a table or view that does not exist')>0;
select tag_name from text_tags where matches(tag_query, 'I have a table and some chairs')>0;
