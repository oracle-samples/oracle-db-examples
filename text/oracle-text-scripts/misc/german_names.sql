drop table emp;

create table emp
  ( id number(4) not null
  , name varchar2(30)
  )
/

insert into emp values (1, 'Muller' );
insert into emp values (2, 'Mueller' );
insert into emp values (3, 'Müller' );
insert into emp values (4, 'Kröller' );
insert into emp values (5, 'Kruller' );
insert into emp values (6, 'Kroeller' );
insert into emp values (7, 'Albertstrasse' );
insert into emp values (8, 'AlbertStraße' );
insert into emp values (9, 'Beer' );
insert into emp values (10, 'Baer' );
insert into emp values (11, 'Bär' );
insert into emp values (12, 'Hoffmann' );
insert into emp values (13, 'Hofman' );

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

create index emp_idx1 on emp(name) 
  indextype is ctxsys.context 
  parameters ('WORDLIST myword DATASTORE ctxsys.default_datastore LEXER mylex STOPLIST ctxsys.empty_stoplist SYNC (on commit)')
/

-- The ? indicates fuzzy matching
SELECT id, name, score(1) as score FROM emp WHERE contains(name, '?Müller', 1) > 0;
SELECT id, name, score(1) as score FROM emp WHERE contains(name, '?Mueller', 1) > 0;

