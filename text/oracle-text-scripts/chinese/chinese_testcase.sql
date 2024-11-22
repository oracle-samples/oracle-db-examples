-- example of a testcase using Chinese characters
-- to see the characters in SQL*Plus you will need to set NLS_LANG before
-- starting SQL*Plus, eg:
-- export NLS_LANG=american_america.al32utf8

-- the use of TO_NUMBER here is a bit old-fashioned, most people would use
-- 0xFFAABB or similar to specify hex characters.

-- I believe the original intention of this test was to test a bug involving 
-- Chinese characters combined with western numbers.

connect system/oracle

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

insert into SIMPLE_TEST (ID, CONTENT) 
values (1, 
chr(to_number( 'F0A0B586', 'xxxxxxxx')) || 
'10' || chr(to_number( 'F0A0B586', 'xxxxxxxx')) || 
'(??10' || 
chr(to_number( 'F0A0B586', 'xxxxxxxx')) || 
')'); 


insert into SIMPLE_TEST (ID, CONTENT) 
values (2, 
chr(to_number( 'F0A0B586', 'xxxxxxxx')) || 
'10' || chr(to_number( 'F0A0B586', 'xxxxxxxx')) || 
'(10' || 
chr(to_number( 'F0A0B586', 'xxxxxxxx')) || 
')'); 

insert into SIMPLE_TEST (ID, CONTENT) 
values (3, 
chr(to_number( 'F0A0B586', 'xxxxxxxx')) || 
'10' || chr(to_number( 'F0A0B586', 'xxxxxxxx')) || 
'(' || chr(to_number( 'e69ca8', 'xxxxxx' )) ||
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
