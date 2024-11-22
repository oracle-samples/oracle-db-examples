-- this should be a test of german decompounding, but it doesn't seem to
-- work
-- Although when we index 'hauptbahnhof' we get tokens of type 9 for 
-- haupt and bahnhof, we can't seem to search on them

drop table detext;

create table detext
  ( id number(4) not null
  , name varchar2(30)
  )
/

insert into detext values (1, 'Hauptbahnhof');

exec ctx_ddl.drop_preference('mylex')

begin
  ctx_ddl.create_preference('mylex', 'BASIC_LEXER');
  ctx_ddl.set_attribute ( 'mylex', 'index_stems', 'GERMAN');
  ctx_ddl.set_attribute ( 'mylex', 'composite', 'GERMAN');
  ctx_ddl.set_attribute ( 'mylex', 'alternate_spelling', 'GERMAN');
end;
/

exec ctx_ddl.drop_preference('myword')

begin 
  ctx_ddl.create_preference('myword', 'BASIC_WORDLIST'); 
  ctx_ddl.set_attribute('myword','FUZZY_MATCH','GERMAN');
end; 
/

create index detext_idx1 on detext(name) 
  indextype is ctxsys.context 
  parameters ('WORDLIST myword DATASTORE ctxsys.default_datastore LEXER mylex SYNC (on commit)')
/

select token_text, token_type from dr$detext_idx1$i;

-- this doesn't work
SELECT id, name, score(1) as score FROM detext WHERE contains(name, '$bahnhof', 1) > 0;

-- but this does
SELECT id, name, score(1) as score FROM detext WHERE contains(name, '$haupt', 1) > 0;
