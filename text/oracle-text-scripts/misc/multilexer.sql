begin
    execute immediate 'drop table text_search';
exception
when others then
     null;
end;    
/

create table text_search (content clob, lang varchar2(3) );
/

insert into text_search values ('Sun rises in the east','eng');
insert into text_search values ('Sun cet evening','fre');
insert into text_search values ('the green color grass', 'ame');
insert into text_search values ('the green colour grass', 'eng');
commit;
/
begin
    ctx_ddl.drop_preference('global_lexer');
exception 
when others then
     null;    
end;
/
 
begin   
    ctx_ddl.drop_preference('english_lexer');
exception 
when others then
     null;    
end;
/
begin   
    ctx_ddl.drop_preference('american_lexer');
exception 
when others then
     null;    
end;
/
begin    
    ctx_ddl.drop_preference('french_lexer');
exception 
when others then
     null;    
end;
/
begin    
    ctx_ddl.drop_preference('german_lexer');
exception 
when others then
     null;    
end;
/

begin
    ctx_ddl.create_preference('english_lexer','basic_lexer');
    ctx_ddl.create_preference('american_lexer','basic_lexer');
    ctx_ddl.create_preference('french_lexer','basic_lexer');
    ctx_ddl.create_preference('german_lexer','basic_lexer');
    ctx_ddl.set_attribute('german_lexer','composite','german');
    ctx_ddl.set_attribute('german_lexer','mixed_case','yes');
    ctx_ddl.set_attribute('german_lexer','alternate_spelling','german');
end;
/

begin
    ctx_ddl.create_preference('global_lexer', 'multi_lexer');
    ctx_ddl.add_sub_lexer('global_lexer','english','english_lexer','eng');
    ctx_ddl.add_sub_lexer('global_lexer','american','american_lexer', 'ame');
    ctx_ddl.add_sub_lexer('global_lexer','french','french_lexer','fre');
    ctx_ddl.add_sub_lexer('global_lexer','german','german_lexer','ger');
    ctx_ddl.add_sub_lexer('global_lexer','default','english_lexer');
end;
/

begin
    ctx_ddl.drop_preference('mywordlist');
exception
when others then
     null;
end;
/

begin
    ctx_ddl.create_preference('mywordlist', 'BASIC_WORDLIST');
    ctx_ddl.set_attribute('mywordlist','STEMMER','ENGLISH');
end;
/

begin
    ctx_ddl.drop_stoplist('multistop');
exception
when others then
     null;
end;
/

begin
    ctx_ddl.create_stoplist('multistop', 'MULTI_STOPLIST');
    ctx_ddl.add_stopword('multistop', 'cet','french');
    ctx_ddl.add_stopword('multistop', 'the','EN');
    ctx_ddl.add_stopword('multistop', 'for','EN');
    ctx_ddl.add_stopword('multistop', 'all','EN');
    ctx_ddl.add_stopword('multistop', 'in','EN');
    ctx_ddl.add_stopword('multistop', 'colour','EN');
    ctx_ddl.add_stopword('multistop', 'color','american');
end;
/

begin
    execute immediate 'drop index my_text_search_idx';
exception
when others then
     null;
end;
/

CREATE INDEX my_text_search_idx ON text_search(content) 
INDEXTYPE IS CTXSYS.CONTEXT 
parameters ('datastore ctxsys.direct_datastore filter ctxsys.null_filter lexer global_lexer wordlist mywordlist  language column lang stoplist multistop');

alter session set nls_language = 'american';

select * from text_search where  contains(content,'Sun rises in the east') >0; 

alter session set nls_language = 'english' ;    

select * from text_search where  contains(content,'Sun rises in the east') >0; 
