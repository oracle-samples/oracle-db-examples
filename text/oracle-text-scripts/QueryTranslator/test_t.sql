-- set serveroutput on 
set feedback off
set pagesize 50

drop table avtest;
create table avtest(text varchar2(255));

insert into avtest values ('cat');
insert into avtest values ('cat dog');
insert into avtest values ('cat cat dog');
insert into avtest values ('cat dog xx cat dog xx cat dog');
insert into avtest values ('cat cat cat cat cat xx dog');
insert into avtest values ('cat cat cat cat cat cat cat xx dog');
insert into avtest values ('cat cat xx dog dog dog dog dog');
insert into avtest values ('cat dog dog rabbit');
insert into avtest values ('cat dog rabbit fox');
insert into avtest values ('dog rabbit fox');
insert into avtest values ('rabbit fox');
insert into avtest values ('cat <seca>dog</seca><secb>fox sheep cow</secb>');
insert into avtest values ('cat <seca>rabbit</seca><secb>fox sheep cow</secb>');
insert into avtest values ('cat <seca>dog rabbit</seca><secb>fox sheep cow</secb>');
insert into avtest values ('cat <seca>dog rabbit cow</seca><secb>fox sheep cow</secb>');
insert into avtest values ('dog <seca>rabbit</seca><secb>fox sheep cow</secb>');
insert into avtest values ('dog <seca>dog rabbit</seca><secb>fox sheep cow</secb>');
insert into avtest values ('dog <seca>dog cat rabbit</seca><secb>fox sheep cow</secb>');
insert into avtest values ('dog <seca>dog dog rabbit</seca><secb>fox sheep cow</secb>');
insert into avtest values ('dog <seca>dog rabbit cow</seca><secb>fox sheep cow</secb>');
insert into avtest values ('cat horse <seca>dog rabbit</seca><secb>fox sheep cow</secb>');
insert into avtest values ('cat cat <seca>dog rabbit</seca><secb>fox sheep cow</secb>');
insert into avtest values ('cat mouse <seca>dog rabbit cow</seca><secb>fox sheep cow</secb>');
insert into avtest values ('cat sheep cow <secb>sheep cow<secb>');
insert into avtest values ('catty doggy sheepy rabbit<secb>cow</secb>');
insert into avtest values ('cat-dog rabbit-fox');
insert into avtest values ('cat*dog rabbit*fox');
insert into avtest values ('cat*dog rabbit*fox');
insert into avtest values ('cat#doggy');
insert into avtest values ('cat-dog rabbit fox');


exec ctx_ddl.drop_preference     ( 'lex' )
exec ctx_ddl.create_preference   ( 'lex', 'basic_lexer' )
exec ctx_ddl.set_attribute       ( 'lex', 'PRINTJOINS', '-')
exec ctx_ddl.set_attribute       ( 'lex', 'SKIPJOINS',  '*#')
exec ctx_ddl.drop_section_group  ( 'sg' )
exec ctx_ddl.create_section_group( 'sg',  'basic_section_group' )
exec ctx_ddl.add_field_section   ( 'sg',  'seca', 'seca', false )
exec ctx_ddl.add_field_section   ( 'sg',  'secb', 'secb', false )
create index avtestindex on avtest(text) indextype is ctxsys.context
parameters ('lexer lex section group sg');

column text format a65
column score format 99.999

set feedback 1
set echo on

select score(1) score, text from avtest where contains (text, parser.simplesearch(
'cat'
),1) > 0 order by score desc;
select score(1) score, text from avtest where contains (text, parser.simplesearch(
'+cat'
),1) > 0 order by score desc;
select score(1) score, text from avtest where contains (text, parser.simplesearch(
'+cat dog'
),1) > 0 order by score desc;
select score(1) score, text from avtest where contains (text, parser.simplesearch(
'+cat +dog'
),1) > 0 order by score desc;
select score(1) score, text from avtest where contains (text, parser.simplesearch(
'cat dog +rabbit'
),1) > 0 order by score desc;
select score(1) score, text from avtest where contains (text, parser.simplesearch(
'seca:(dog)'
),1) > 0 order by score desc;
select score(1) score, text from avtest where contains (text, parser.simplesearch(
'cat +secb:(albatross)'
),1) > 0 order by score desc;
select score(1) score, text from avtest where contains (text, parser.simplesearch(
'+seca:(rabbit) +secb:(sheep) +cat'
),1) > 0 order by score desc;
select score(1) score, text from avtest where contains (text, parser.simplesearch(
'cat +secb:(+albatross)'
),1) > 0 order by score desc;
select score(1) score, text from avtest where contains (text, parser.simplesearch(
'cat +secb:(albatross cow)'
),1) > 0 order by score desc;
select score(1) score, text from avtest where contains (text, parser.simplesearch(
'cat +secb:(albatross flamingo)'
),1) > 0 order by score desc;
select score(1) score, text from avtest where contains (text, parser.simplesearch(
'cat secb:(albatross flamingo)'
),1) > 0 order by score desc;
select score(1) score, text from avtest where contains (text, parser.simplesearch(
'cat +secb:(fox cow)'
),1) > 0 order by score desc;
select score(1) score, text from avtest where contains (text, parser.simplesearch(
'dog +secb:(cow)'
),1) > 0 order by score desc;
select score(1) score, text from avtest where contains (text, parser.simplesearch(
'dog +secb:(cow)'
),1) > 0 order by score desc;
select score(1) score, text from avtest where contains (text, parser.simplesearch(
'cat +secb:(cow)'
),1) > 0 order by score desc;
select score(1) score, text from avtest where contains (text, parser.simplesearch(
'secb:(+fox cow)'
),1) > 0 order by score desc;
select score(1) score, text from avtest where contains (text, parser.simplesearch(
'catt*'
),1) > 0 order by score desc;

-- prompt progressive relaxation
column "Query Text" format a111
set linesize 111
set long 500000
set pagesize 50

variable :qry varchar2(4000)

exec parser.setIndexName('avtestindex')
exec parser.setScoreType(parser.scoreTypeFloat)

select parser.progrelax('cat') "Query Text" from dual;
select score(1) score, text from avtest where contains (text, parser.progrelax(
'cat'
),1) > 0 order by score desc;
select parser.progrelax('+cat') "Query Text" from dual;
select score(1) score, text from avtest where contains (text, parser.progrelax(
'+cat'
),1) > 0 order by score desc;
select parser.progrelax('+cat dog') "Query Text" from dual;
select score(1) score, text from avtest where contains (text, parser.progrelax(
'+cat dog'
),1) > 0 order by score desc;
select parser.progrelax('+cat +dog') "Query Text" from dual;
select score(1) score, text from avtest where contains (text, parser.progrelax(
'+cat +dog'
),1) > 0 order by score desc;
select parser.progrelax('+dog +cat') "Query Text" from dual;
select score(1) score, text from avtest where contains (text, parser.progrelax(
'+dog +cat'
),1) > 0 order by score desc;
select parser.progrelax('dog cat') "Query Text" from dual;
select score(1) score, text from avtest where contains (text, parser.progrelax(
'dog cat'
),1) > 0 order by score desc;
select parser.progrelax('cat dog +rabbit') "Query Text" from dual;
select score(1) score, text from avtest where contains (text, parser.progrelax(
'cat dog +rabbit'
),1) > 0 order by score desc;
select parser.progrelax('cat rabbit') "Query Text" from dual;
select score(1) score, text from avtest where contains (text, parser.progrelax(
'cat rabbit'
),1) > 0 order by score desc;
select parser.progrelax('"cat rabbit"') "Query Text" from dual;
select score(1) score, text from avtest where contains (text, parser.progrelax(
'"cat rabbit"'
),1) > 0 order by score desc;
select parser.progrelax('+cat +rabbit') "Query Text" from dual;
select score(1) score, text from avtest where contains (text, parser.progrelax(
'+cat +rabbit'
),1) > 0 order by score desc;
select parser.progrelax('seca:(dog)') "Query Text" from dual;
select score(1) score, text from avtest where contains (text, parser.progrelax(
'seca:(dog)'
),1) > 0 order by score desc;
select parser.progrelax('seca:(+dog)') "Query Text" from dual;
select score(1) score, text from avtest where contains (text, parser.progrelax(
'seca:(+dog)'
),1) > 0 order by score desc;
select parser.progrelax('seca:(-dog)') "Query Text" from dual;
select score(1) score, text from avtest where contains (text, parser.progrelax(
'seca:(-dog)'
),1) > 0 order by score desc;
select parser.progrelax('cat +secb:(albatross)') "Query Text" from dual;
select score(1) score, text from avtest where contains (text, parser.progrelax(
'cat +secb:(albatross)'
),1) > 0 order by score desc;
select parser.progrelax('+seca:(rabbit) +secb:(sheep) +cat') "Query Text" from dual;
select score(1) score, text from avtest where contains (text, parser.progrelax(
'+seca:(rabbit) +secb:(sheep) +cat'
),1) > 0 order by score desc;
select parser.progrelax('cat +secb:(+albatross)') "Query Text" from dual;
select score(1) score, text from avtest where contains (text, parser.progrelax(
'cat +secb:(+albatross)'
),1) > 0 order by score desc;
select parser.progrelax('cat +secb:(albatross cow)') "Query Text" from dual;
select score(1) score, text from avtest where contains (text, parser.progrelax(
'cat +secb:(albatross cow)'
),1) > 0 order by score desc;
select parser.progrelax('cat +secb:(albatross flamingo)') "Query Text" from dual;
select score(1) score, text from avtest where contains (text, parser.progrelax(
'cat +secb:(albatross flamingo)'
),1) > 0 order by score desc;
select parser.progrelax('cat secb:(albatross flamingo)') "Query Text" from dual;
select score(1) score, text from avtest where contains (text, parser.progrelax(
'cat secb:(albatross flamingo)'
),1) > 0 order by score desc;
select parser.progrelax('cat +secb:(fox cow)') "Query Text" from dual;
select score(1) score, text from avtest where contains (text, parser.progrelax(
'cat +secb:(fox cow)'
),1) > 0 order by score desc;
select parser.progrelax('dog +secb:(cow)') "Query Text" from dual;
select score(1) score, text from avtest where contains (text, parser.progrelax(
'dog +secb:(cow)'
),1) > 0 order by score desc;
select parser.progrelax('dog +secb:(cow)') "Query Text" from dual;
select score(1) score, text from avtest where contains (text, parser.progrelax(
'dog +secb:(cow)'
),1) > 0 order by score desc;
select parser.progrelax('cat +secb:(cow)') "Query Text" from dual;
select score(1) score, text from avtest where contains (text, parser.progrelax(
'cat +secb:(cow)'
),1) > 0 order by score desc;
select parser.progrelax('secb:(+fox cow)') "Query Text" from dual;
select score(1) score, text from avtest where contains (text, parser.progrelax(
'secb:(+fox cow)'
),1) > 0 order by score desc;
select parser.progrelax('seca:(dog rabbit)') "Query Text" from dual;
select score(1) score, text from avtest where contains (text, parser.progrelax(
'seca:(dog rabbit)'
),1) > 0 order by score desc;
select parser.progrelax('catt*') "Query Text" from dual;
select score(1) score, text from avtest where contains (text, parser.progrelax(
'catt*'
),1) > 0 order by score desc;
select parser.progrelax('cat-dog') "Query Text" from dual;
select score(1) score, text from avtest where contains (text, parser.progrelax(
'cat-dog'
),1) > 0 order by score desc;
select parser.progrelax('cat*dog') "Query Text" from dual;
select score(1) score, text from avtest where contains (text, parser.progrelax(
'cat*dog'
),1) > 0 order by score desc;
select parser.progrelax('cat*dog*') "Query Text" from dual;
select score(1) score, text from avtest where contains (text, parser.progrelax(
'cat*dog*'
),1) > 0 order by score desc;
select parser.progrelax('cat +seca:(rabbit +dog) -mouse -horse') "Query Text" from dual;
select score(1) score, text from avtest where contains (text, parser.progrelax(
'cat +seca:(rabbit +dog) -mouse -horse'
),1) > 0 order by score(1) desc;
select parser.progrelax('the angry cat attacked the ugly horse. They then both attacked the dog who was scared of the mouse. Afterwards, the went for a cup of tea with the rabbit') "Query Text" from dual;
select score(1) score, text from avtest where contains (text, parser.progrelax(
'the angry cat attacked the ugly horse. They then both attacked the dog who was scared of the mouse. Afterwards, the went for a cup of tea with the rabbit'
),1) > 0 order by score(1) desc;

exec parser.setWildCard('%')

select score(1) score, text from avtest where contains (text, parser.progrelax('rab%'), 1) > 0 order by score(1) desc;

set echo off
set feedback on
