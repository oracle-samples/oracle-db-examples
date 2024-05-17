begin
    ctx_ddl.drop_preference ( 'my_lexer');
end;
/
begin
    ctx_ddl.create_preference ( 'my_lexer', 'BASIC_LEXER' );
    ctx_ddl.set_attribute( 'my_lexer', 'BASE_LETTER', 'true' );
    ctx_ddl.set_attribute( 'my_lexer', 'OVERRIDE_BASE_LETTER', 'true');
    ctx_ddl.set_attribute( 'my_lexer', 'ALTERNATE_SPELLING','german' );
end;
/

drop table tt;
create table tt(a1 number primary key,text varchar2(45));
 
 -- town name "Rouède", accent on the e
insert into tt values (1,'rou'||unistr('\00E8')||'de');
 -- shön with accent (wa)
insert into tt values (2,'wasch'||unistr('\00F6')||'n');
 -- shon no accent (na)
insert into tt values (3,'naschon');
 -- muenchen alternate form (af)
insert into tt values (4,'afmuenchen');

commit;

select * from tt;

create index tta on tt(text) indextype is ctxsys.context
 parameters ( 'lexer  my_lexer' );

set feedback 2

select token_text, token_type from dr$tta$i;

-- PROMPT searching for the base letter form, without accent on the first e
-- select * from tt where contains(text,'Rouede')>0;

-- PROMPT and with the accent
-- select * from tt where contains(text,'Rou'||unistr('\00E8')||'de') > 0;

set echo on

select * from tt where contains(text,'afm'||unistr('\00FC')||'nchen')>0;
select * from tt where contains(text,'afmuenchen') > 0;

set echo on

--select * from tt where contains(text,'naschoen') > 0;
--select * from tt where contains(text,'naschon') > 0;
--select * from tt where contains(text,'na'||unistr('\00F6')||'n') > 0;

-- select * from tt where contains(text,'waschon') > 0;
-- select * from tt where contains(text,'waschoen') > 0;
-- select * from tt where contains(text,'wasch'||unistr('\00F6')||'n') > 0;

set echo off

--select * from tt where contains(text,'nasch'||unistr('\00F6')||'n') > 0;

drop table test_explain;
create table test_explain(
         explain_id varchar2(30),
         id number,
         parent_id number,
         operation varchar2(30),
         options varchar2(30),
         object_name varchar2(64),
         position number,
         cardinality number);

begin
ctx_query.explain(
         index_name => 'tta',
         text_query => 'wasch'||unistr('\00F6')||'n',
         explain_table => 'test_explain',
         sharelevel => 0,
         explain_id => 'Test');
end;
/

col explain_id for a10
col id for 99
col parent_id for 99
col operation for a10
col options for a10
col object_name for a20
col position for 99

select explain_id, id, parent_id, operation, options, object_name, position
from test_explain order by id;
