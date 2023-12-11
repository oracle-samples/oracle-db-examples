drop table test;
create table test (text varchar2(40), lang varchar2(15));

insert into test values ('sh'||UNISTR('\00F6')||'n', 'german');

exec ctx_ddl.drop_preference('multilex')
exec ctx_ddl.drop_preference('def_lex')
exec ctx_ddl.drop_preference('ger_lex')

exec ctx_ddl.create_preference('ger_lex', 'basic_lexer')
exec ctx_ddl.set_attribute('ger_lex', 'base_letter', 'true')
exec ctx_ddl.set_attribute('ger_lex', 'override_base_letter', 'true')
exec ctx_ddl.set_attribute('ger_lex', 'alternate_spelling', 'NONE')

exec ctx_ddl.create_preference('def_lex', 'basic_lexer')
exec ctx_ddl.set_attribute('def_lex', 'base_letter', 'false')
exec ctx_ddl.set_attribute('def_lex', 'override_base_letter', 'false')
exec ctx_ddl.set_attribute('def_lex', 'alternate_spelling', 'NONE')

exec ctx_ddl.create_preference('multilex', 'MULTI_LEXER')
exec ctx_ddl.add_sub_lexer('multilex', 'german', 'my_lex')
exec ctx_ddl.add_sub_lexer('multilex', 'default', 'def_lex')

create index testindex on test(text) indextype is ctxsys.context parameters ('lexer multilex language column lang');

select 'w/acc BL->T OBL->T AS->None' "Options", text "Text", token_text "Tokens" from test, dr$testindex$i;

set feedback 2

-- 1 German

prompt
prompt German query with accent
select text from test where contains(text, '
<query>
  <textquery lang="german">
    sh'||UNISTR('\00F6')||'n
  </textquery>
</query>') > 0;

prompt German query without accent
select text from test where contains(text, '
<query>
  <textquery lang="german">
    shon
  </textquery>
</query>') > 0;

prompt German query with alt form
select text from test where contains(text, '
<query>
  <textquery lang="german">
    shoen
  </textquery>
</query>') > 0;

-- 2 French

prompt French query with accent
select text from test where contains(text, '
<query>
  <textquery lang="FRENCH">
    sh'||UNISTR('\00F6')||'n
  </textquery>
</query>') > 0;

prompt French query without accent
select text from test where contains(text, '
<query>
  <textquery lang="FRENCH">
    shon
  </textquery>
</query>') > 0;

prompt French query with alt form
select text from test where contains(text, '
<query>
  <textquery lang="FRENCH">
    shoen
  </textquery>
</query>') > 0;

set feedback off

drop table test;
create table test (text varchar2(40), lang varchar2(15));

insert into test values ('shon', 'german');

exec ctx_ddl.drop_preference('multilex')
exec ctx_ddl.drop_preference('def_lex')
exec ctx_ddl.drop_preference('ger_lex')

exec ctx_ddl.create_preference('ger_lex', 'basic_lexer')
exec ctx_ddl.set_attribute('ger_lex', 'base_letter', 'true')
exec ctx_ddl.set_attribute('ger_lex', 'override_base_letter', 'true')
exec ctx_ddl.set_attribute('ger_lex', 'alternate_spelling', 'NONE')

exec ctx_ddl.create_preference('def_lex', 'basic_lexer')
exec ctx_ddl.set_attribute('def_lex', 'base_letter', 'false')
exec ctx_ddl.set_attribute('def_lex', 'override_base_letter', 'false')
exec ctx_ddl.set_attribute('def_lex', 'alternate_spelling', 'NONE')

exec ctx_ddl.create_preference('multilex', 'MULTI_LEXER')
exec ctx_ddl.add_sub_lexer('multilex', 'german', 'my_lex')
exec ctx_ddl.add_sub_lexer('multilex', 'default', 'def_lex')

create index testindex on test(text) indextype is ctxsys.context parameters ('lexer multilex language column lang');

select 'w/acc BL->T OBL->T AS->None' "Options", text "Text", token_text "Tokens" from test, dr$testindex$i;

set feedback 2

-- 1 German

prompt
prompt German query with accent
select text from test where contains(text, '
<query>
  <textquery lang="german">
    sh'||UNISTR('\00F6')||'n
  </textquery>
</query>') > 0;

prompt German query without accent
select text from test where contains(text, '
<query>
  <textquery lang="german">
    shon
  </textquery>
</query>') > 0;

prompt German query with alt form
select text from test where contains(text, '
<query>
  <textquery lang="german">
    shoen
  </textquery>
</query>') > 0;

-- 2 French

prompt French query with accent
select text from test where contains(text, '
<query>
  <textquery lang="FRENCH">
    sh'||UNISTR('\00F6')||'n
  </textquery>
</query>') > 0;

prompt French query without accent
select text from test where contains(text, '
<query>
  <textquery lang="FRENCH">
    shon
  </textquery>
</query>') > 0;

prompt French query with alt form
select text from test where contains(text, '
<query>
  <textquery lang="FRENCH">
    shoen
  </textquery>
</query>') > 0;

set feedback off
