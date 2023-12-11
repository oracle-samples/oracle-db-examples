set feedback off


drop table test;
create table test (text varchar2(40));

insert into test values ('sh'||UNISTR('\00F6')||'n');
exec ctx_ddl.drop_preference('my_lex')
exec ctx_ddl.create_preference('my_lex', 'basic_lexer')
exec ctx_ddl.set_attribute('my_lex', 'base_letter', 'yes')
exec ctx_ddl.set_attribute('my_lex', 'override_base_letter', 'true')
exec ctx_ddl.set_attribute('my_lex', 'alternate_spelling', 'German')

create index testindex on test(text) indextype is ctxsys.context parameters ('lexer my_lex');

select text from test;
select token_text "w/acc BL->F OBL->F AS->None" from dr$testindex$i;

drop table test;
create table test (text varchar2(40));

insert into test values ('sh'||UNISTR('\00F6')||'n');
exec ctx_ddl.drop_preference('my_lex')
exec ctx_ddl.create_preference('my_lex', 'basic_lexer')
exec ctx_ddl.set_attribute('my_lex', 'base_letter', 'true')
exec ctx_ddl.set_attribute('my_lex', 'override_base_letter', 'false')
exec ctx_ddl.set_attribute('my_lex', 'alternate_spelling', 'NONE')

create index testindex on test(text) indextype is ctxsys.context parameters ('lexer my_lex');

select text from test;
select token_text "w/acc BL->T OBL->F AS->None" from dr$testindex$i;

drop table test;
create table test (text varchar2(40));

insert into test values ('sh'||UNISTR('\00F6')||'n');
exec ctx_ddl.drop_preference('my_lex')
exec ctx_ddl.create_preference('my_lex', 'basic_lexer')
exec ctx_ddl.set_attribute('my_lex', 'base_letter', 'true')
exec ctx_ddl.set_attribute('my_lex', 'override_base_letter', 'true')
exec ctx_ddl.set_attribute('my_lex', 'alternate_spelling', 'NONE')

create index testindex on test(text) indextype is ctxsys.context parameters ('lexer my_lex');

select text from test;
select token_text "w/acc BL->T OBL->T AS->None" from dr$testindex$i;

-- Same with alternate spelling = german

drop table test;
create table test (text varchar2(40));

insert into test values ('sh'||UNISTR('\00F6')||'n');
exec ctx_ddl.drop_preference('my_lex')
exec ctx_ddl.create_preference('my_lex', 'basic_lexer')
exec ctx_ddl.set_attribute('my_lex', 'base_letter', 'false')
exec ctx_ddl.set_attribute('my_lex', 'override_base_letter', 'false')
exec ctx_ddl.set_attribute('my_lex', 'alternate_spelling', 'GERMAN')

create index testindex on test(text) indextype is ctxsys.context parameters ('lexer my_lex');

select text from test;
select token_text "w/acc BL->F OBL->F AS->German" from dr$testindex$i;

drop table test;
create table test (text varchar2(40));

insert into test values ('sh'||UNISTR('\00F6')||'n');
exec ctx_ddl.drop_preference('my_lex')
exec ctx_ddl.create_preference('my_lex', 'basic_lexer')
exec ctx_ddl.set_attribute('my_lex', 'base_letter', 'true')
exec ctx_ddl.set_attribute('my_lex', 'override_base_letter', 'false')
exec ctx_ddl.set_attribute('my_lex', 'alternate_spelling', 'GERMAN')

create index testindex on test(text) indextype is ctxsys.context parameters ('lexer my_lex');

select text from test;
select token_text "w/acc BL->T OBL->F AS->German" from dr$testindex$i;

drop table test;
create table test (text varchar2(40));

insert into test values ('sh'||UNISTR('\00F6')||'n');
exec ctx_ddl.drop_preference('my_lex')
exec ctx_ddl.create_preference('my_lex', 'basic_lexer')
exec ctx_ddl.set_attribute('my_lex', 'base_letter', 'true')
exec ctx_ddl.set_attribute('my_lex', 'override_base_letter', 'true')
exec ctx_ddl.set_attribute('my_lex', 'alternate_spelling', 'GERMAN')

create index testindex on test(text) indextype is ctxsys.context parameters ('lexer my_lex');

select text from test;
select token_text "w/acc BL->T OBL->T AS->German" from dr$testindex$i;

-- Now without accent

drop table test;
create table test (text varchar2(40));

insert into test values ('shon');
exec ctx_ddl.drop_preference('my_lex')
exec ctx_ddl.create_preference('my_lex', 'basic_lexer')
exec ctx_ddl.set_attribute('my_lex', 'base_letter', 'false')
exec ctx_ddl.set_attribute('my_lex', 'override_base_letter', 'false')
exec ctx_ddl.set_attribute('my_lex', 'alternate_spelling', 'NONE')

create index testindex on test(text) indextype is ctxsys.context parameters ('lexer my_lex');

select text from test;
select token_text "noacc BL->F OBL->F AS->None" from dr$testindex$i;

drop table test;
create table test (text varchar2(40));

insert into test values ('shon');
exec ctx_ddl.drop_preference('my_lex')
exec ctx_ddl.create_preference('my_lex', 'basic_lexer')
exec ctx_ddl.set_attribute('my_lex', 'base_letter', 'true')
exec ctx_ddl.set_attribute('my_lex', 'override_base_letter', 'false')
exec ctx_ddl.set_attribute('my_lex', 'alternate_spelling', 'NONE')

create index testindex on test(text) indextype is ctxsys.context parameters ('lexer my_lex');

select text from test;
select token_text "noacc BL->T OBL->F AS->None" from dr$testindex$i;

drop table test;
create table test (text varchar2(40));

insert into test values ('shon');
exec ctx_ddl.drop_preference('my_lex')
exec ctx_ddl.create_preference('my_lex', 'basic_lexer')
exec ctx_ddl.set_attribute('my_lex', 'base_letter', 'true')
exec ctx_ddl.set_attribute('my_lex', 'override_base_letter', 'true')
exec ctx_ddl.set_attribute('my_lex', 'alternate_spelling', 'NONE')

create index testindex on test(text) indextype is ctxsys.context parameters ('lexer my_lex');

select text from test;
select token_text "noacc BL->T OBL->T AS->None" from dr$testindex$i;

-- Same with alternate spelling = german

drop table test;
create table test (text varchar2(40));

insert into test values ('shon');
exec ctx_ddl.drop_preference('my_lex')
exec ctx_ddl.create_preference('my_lex', 'basic_lexer')
exec ctx_ddl.set_attribute('my_lex', 'base_letter', 'false')
exec ctx_ddl.set_attribute('my_lex', 'override_base_letter', 'false')
exec ctx_ddl.set_attribute('my_lex', 'alternate_spelling', 'GERMAN')

create index testindex on test(text) indextype is ctxsys.context parameters ('lexer my_lex');

select text from test;
select token_text "noacc BL->F OBL->F AS->German" from dr$testindex$i;

drop table test;
create table test (text varchar2(40));

insert into test values ('shon');
exec ctx_ddl.drop_preference('my_lex')
exec ctx_ddl.create_preference('my_lex', 'basic_lexer')
exec ctx_ddl.set_attribute('my_lex', 'base_letter', 'true')
exec ctx_ddl.set_attribute('my_lex', 'override_base_letter', 'false')
exec ctx_ddl.set_attribute('my_lex', 'alternate_spelling', 'GERMAN')

create index testindex on test(text) indextype is ctxsys.context parameters ('lexer my_lex');

select text from test;
select token_text "noacc BL->T OBL->F AS->German" from dr$testindex$i;

drop table test;
create table test (text varchar2(40));

insert into test values ('shon');
exec ctx_ddl.drop_preference('my_lex')
exec ctx_ddl.create_preference('my_lex', 'basic_lexer')
exec ctx_ddl.set_attribute('my_lex', 'base_letter', 'true')
exec ctx_ddl.set_attribute('my_lex', 'override_base_letter', 'true')
exec ctx_ddl.set_attribute('my_lex', 'alternate_spelling', 'GERMAN')

create index testindex on test(text) indextype is ctxsys.context parameters ('lexer my_lex');

select text from test;
select token_text "noacc BL->T OBL->T AS->German" from dr$testindex$i;

-- Now starting with alternate spelling form

drop table test;
create table test (text varchar2(40));

insert into test values ('shoen');
exec ctx_ddl.drop_preference('my_lex')
exec ctx_ddl.create_preference('my_lex', 'basic_lexer')
exec ctx_ddl.set_attribute('my_lex', 'base_letter', 'false')
exec ctx_ddl.set_attribute('my_lex', 'override_base_letter', 'false')
exec ctx_ddl.set_attribute('my_lex', 'alternate_spelling', 'NONE')

create index testindex on test(text) indextype is ctxsys.context parameters ('lexer my_lex');

select text from test;
select token_text "altf BL->F OBL->F AS->None" from dr$testindex$i;

drop table test;
create table test (text varchar2(40));

insert into test values ('shoen');
exec ctx_ddl.drop_preference('my_lex')
exec ctx_ddl.create_preference('my_lex', 'basic_lexer')
exec ctx_ddl.set_attribute('my_lex', 'base_letter', 'true')
exec ctx_ddl.set_attribute('my_lex', 'override_base_letter', 'false')
exec ctx_ddl.set_attribute('my_lex', 'alternate_spelling', 'NONE')

create index testindex on test(text) indextype is ctxsys.context parameters ('lexer my_lex');

select text from test;
select token_text "altf BL->T OBL->F AS->None" from dr$testindex$i;

drop table test;
create table test (text varchar2(40));

insert into test values ('shoen');
exec ctx_ddl.drop_preference('my_lex')
exec ctx_ddl.create_preference('my_lex', 'basic_lexer')
exec ctx_ddl.set_attribute('my_lex', 'base_letter', 'true')
exec ctx_ddl.set_attribute('my_lex', 'override_base_letter', 'true')
exec ctx_ddl.set_attribute('my_lex', 'alternate_spelling', 'NONE')

create index testindex on test(text) indextype is ctxsys.context parameters ('lexer my_lex');

select text from test;
select token_text "altf BL->T OBL->T AS->None" from dr$testindex$i;

-- Same with alternate spelling = german

drop table test;
create table test (text varchar2(40));

insert into test values ('shoen');
exec ctx_ddl.drop_preference('my_lex')
exec ctx_ddl.create_preference('my_lex', 'basic_lexer')
exec ctx_ddl.set_attribute('my_lex', 'base_letter', 'false')
exec ctx_ddl.set_attribute('my_lex', 'override_base_letter', 'false')
exec ctx_ddl.set_attribute('my_lex', 'alternate_spelling', 'GERMAN')

create index testindex on test(text) indextype is ctxsys.context parameters ('lexer my_lex');

select text from test;
select token_text "altf BL->F OBL->F AS->German" from dr$testindex$i;

drop table test;
create table test (text varchar2(40));

insert into test values ('shoen');
exec ctx_ddl.drop_preference('my_lex')
exec ctx_ddl.create_preference('my_lex', 'basic_lexer')
exec ctx_ddl.set_attribute('my_lex', 'base_letter', 'true')
exec ctx_ddl.set_attribute('my_lex', 'override_base_letter', 'false')
exec ctx_ddl.set_attribute('my_lex', 'alternate_spelling', 'GERMAN')

create index testindex on test(text) indextype is ctxsys.context parameters ('lexer my_lex');

select text from test;
select token_text "altf BL->T OBL->F AS->German" from dr$testindex$i;

drop table test;
create table test (text varchar2(40));

insert into test values ('shoen');
exec ctx_ddl.drop_preference('my_lex')
exec ctx_ddl.create_preference('my_lex', 'basic_lexer')
exec ctx_ddl.set_attribute('my_lex', 'base_letter', 'true')
exec ctx_ddl.set_attribute('my_lex', 'override_base_letter', 'true')
exec ctx_ddl.set_attribute('my_lex', 'alternate_spelling', 'GERMAN')

create index testindex on test(text) indextype is ctxsys.context parameters ('lexer my_lex');

select text from test;
select token_text "altf BL->T OBL->T AS->German" from dr$testindex$i;

