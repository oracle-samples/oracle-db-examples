exec ctx_ddl.drop_preference('my_lexer');
exec ctx_ddl.drop_stoplist('my_stop');
drop table customer;


create table customer(id number, name varchar2(2000));

insert into customer values(1, 'Valerius Group Xo.');
insert into customer values(2, 'Valérius Ltd.');
insert into customer values(3, 'Valeria');

--optional lexer which tokenizes words
--'BASIC_LEXER' is good enough for most Western white-space delimited languages
--use 'AUTO_LEXER' for Western and non-Western languages 
exec ctx_ddl.create_preference('my_lexer', 'AUTO_LEXER');

--optional stoplist which avoids indexing the words that you list
exec ctx_ddl.create_stoplist('my_stop', 'BASIC_STOPLIST');
exec ctx_ddl.add_stopword('my_stop', 'Xo.');
exec ctx_ddl.add_stopword('my_stop', 'Ltd.');

--create the index with optional parameters 
create index idx on customer(name) 
indextype is ctxsys.context parameters('lexer my_lexer stoplist my_stop');

--list out all words in the index
column token_text format a10
select token_text, token_type from DR$IDX$I order by token_text, token_type;
