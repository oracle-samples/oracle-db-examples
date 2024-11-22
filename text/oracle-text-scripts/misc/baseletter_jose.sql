drop table tnome;
create table tnome (id number primary key, nome varchar2(30));

insert into tnome values (1, 'Maria José da Silva');
insert into tnome values (2, 'Maria José Silva');
insert into tnome values (3, 'Maria Silva');
insert into tnome values (4, 'Maria José Silva');
insert into tnome values (5, 'Maria Jose Silva');
insert into tnome values (6, 'Maria José de la Silva');

-- drop index demo_keywords_idx;

exec ctx_ddl.drop_preference('my_lexer')

begin
  CTX_DDL.CREATE_PREFERENCE ('my_lexer', 'BASIC_LEXER');
  CTX_DDL.SET_ATTRIBUTE ('my_lexer', 'MIXED_CASE', 'NO');
  CTX_DDL.SET_ATTRIBUTE ('my_lexer', 'BASE_LETTER', 'YES');
end;
/

CREATE INDEX DEMO_KEYWORDS_IDX ON tnome (nome) INDEXTYPE IS CTXSYS.CONTEXT  PARAMETERS ('LEXER my_lexer') ;

set echo on
prompt Prove that BASE_LETTER is working...
select * from tnome where contains (nome, 'Jose') > 0;
select * from tnome where contains (nome, 'José') > 0;

prompt Now try a more complex query
select * from tnome where contains ( nome, 'Maria%' ) > 0;
select * from tnome where contains ( nome, 'NEAR( (Maria%, Jose%), 2, true)' ) > 0;
select * from tnome where contains ( nome, 'NEAR( (Maria%, Jose, Silva), 2, true)' ) > 0;

prompt Note that this will also match
select * from tnome where contains ( nome, 'NEAR( (Jose%, Silva), 2, true)' ) > 0;

set echo off
prompt Press Enter to continue...
pause

prompt This is more complicated - if you need to identify first and last terms
prompt you must tag them in some way

prompt Press Enter to continue...
pause

drop table tnome;
create table tnome (id number primary key, nome varchar2(30));

insert into tnome values (1, 'Maria José da Silva');
insert into tnome values (2, 'Maria José Silva');
insert into tnome values (3, 'Maria Silva');
insert into tnome values (4, 'Maria José Silva');
insert into tnome values (5, 'Maria Jose Silva');
insert into tnome values (6, 'Maria José de la Silva');

-- drop index demo_keywords_idx;

exec ctx_ddl.drop_preference('my_lexer')
exec ctx_ddl.drop_preference('my_datastore')

begin
  CTX_DDL.CREATE_PREFERENCE ('my_lexer', 'BASIC_LEXER');
  CTX_DDL.SET_ATTRIBUTE ('my_lexer', 'MIXED_CASE', 'NO');
  CTX_DDL.SET_ATTRIBUTE ('my_lexer', 'BASE_LETTER', 'YES');
end;
/

begin
  CTX_DDL.CREATE_PREFERENCE ('my_datastore', 'MULTI_COLUMN_DATASTORE');
  CTX_DDL.SET_ATTRIBUTE ('my_datastore', 'columns', '''xxstart ''||nome');
  CTX_DDL.SET_ATTRIBUTE ('my_datastore', 'BASE_LETTER', 'YES');
end;
/

CREATE INDEX DEMO_KEYWORDS_IDX ON tnome (nome) INDEXTYPE IS CTXSYS.CONTEXT  
PARAMETERS ('LEXER my_lexer DATASTORE my_datastore') ;

set echo on

select * from tnome where contains ( nome, 'NEAR( (xxstart Maria%, Jose%), 2, true)' ) > 0;
select * from tnome where contains ( nome, 'NEAR( (xxstart Maria%, Jose Silva), 2, true)' ) > 0;
select * from tnome where contains ( nome, 'NEAR( (xxstart Jose%, Silva), 2, true)' ) > 0;
