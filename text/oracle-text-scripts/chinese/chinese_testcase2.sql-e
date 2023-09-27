-- see comments at the start of chinese_testcase.sql

connect system/welcome1

drop user testuser cascade;

grant connect,resource,ctxapp,unlimited tablespace to testuser identified by testuser;

connect testuser/testuser

begin 
  ctx_ddl.create_preference   ('SIMPLE_LEXER',     'WORLD_LEXER'); 
  ctx_ddl.create_section_group('SIMPLE_PATHGROUP', 'PATH_SECTION_GROUP'); 
  ctx_ddl.create_preference   ('SIMPLE_WORDLIST',  'BASIC_WORDLIST'); 
  ctx_ddl.create_preference   ('SIMPLE_STORAGE',   'BASIC_STORAGE'); 
  ctx_ddl.set_attribute       ('SIMPLE_STORAGE',   'BIG_IO', 'YES'); 
end; 
/ 

create table SIMPLE_TEST ( 
ID number primary key, 
CONTENT clob null );

- this one highlights properly

insert into SIMPLE_TEST (ID, CONTENT) 
values (1, 
chr(to_number( 'F0A0B586', 'xxxxxxxx')) || 
'10' || chr(to_number( 'F0A0B586', 'xxxxxxxx')) || 
'(10' || 
chr(to_number( 'F0A0B586', 'xxxxxxxx')) || 
')'); 

-- this highlights the character and the following "("

insert into SIMPLE_TEST (ID, CONTENT) 
values (2, 
chr(to_number( 'F0A0B586', 'xxxxxxxx')) || 
'10' || chr(to_number( 'F0A0B586', 'xxxxxxxx')) || 
'(' || chr(to_number( 'e69ca8', 'xxxxxx' )) ||
chr(to_number( 'e69d90', 'xxxxxx' )) || '10' || 
chr(to_number( 'F0A0B586', 'xxxxxxxx')) || 
')');

-- this highlighs the character and the following space

insert into SIMPLE_TEST (ID, CONTENT) 
values (3, 
chr(to_number( 'F0A0B586', 'xxxxxxxx')) || 
'10' || chr(to_number( 'F0A0B586', 'xxxxxxxx')) || 
' ' || chr(to_number( 'e69ca8', 'xxxxxx' )) ||
chr(to_number( 'e69d90', 'xxxxxx' )) || '10' || 
chr(to_number( 'F0A0B586', 'xxxxxxxx')) || 
')');

create index SIMPLE_TEST$CONTENT ON SIMPLE_TEST(CONTENT) indextype 
is CTXSYS.CONTEXT 
parameters ('WORDLIST SIMPLE_WORDLIST LEXER SIMPLE_LEXER FILTER CTXSYS.NULL_FILTER STOPLIST CTXSYS.EMPTY_STOPLIST SECTION GROUP SIMPLE_PATHGROUP STORAGE SIMPLE_STORAGE');

select * from simple_test;

set serveroutput on

declare
  mklob clob;
  amt   number := 200;
  pos   number := 1;
  line  varchar2(5000);
  i     integer;
begin
  for i in 1..3 loop
    dbms_lob.createtemporary(mklob, true);
    ctx_doc.markup('SIMPLE_TEST$CONTENT', to_char(i), chr(to_number( 'F0A0B586', 'xxxxxxxx' )), mklob);
    dbms_lob.read(mklob, amt, pos, line);
    dbms_output.put_line('id: ' || i || ' Text: ' || line);
    dbms_lob.freetemporary(mklob);
  end loop;
end;
/

