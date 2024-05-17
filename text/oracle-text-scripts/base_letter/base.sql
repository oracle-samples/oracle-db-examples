-- this script shows the effect of various lexer settings on words
-- with accented characters

-- alternate spelling allows for letter combinations instead of
-- accented characters or sharp S.

-- base letter means that accented characters are indexed in their base,
-- or unaccented form

-- override_base_letter may be used where both base letter and alternate
-- spelling are in use. It effectively means that German speakers can search
-- using their own accents, but for text in other languages they don't need
-- to use the accent

-- you can play with the effect of turning these settings on and off
-- and perhaps try adding some other words from other languages

-- character set of this file is UTF8. If using SQL*Plus, you need to
-- set NLS_LANG as follows:

-- export NLS_LANG=american_america.al32utf8

set echo on

drop table foo;

create table foo (text varchar2(30));
insert into foo values ('Schön');

drop table foo2;

create table foo2 (text varchar2(30));
insert into foo2 values ('Schoen');

exec ctx_ddl.drop_preference('test')
exec ctx_ddl.create_preference('test', 'BASIC_LEXER')
exec ctx_ddl.set_attribute('test', 'ALTERNATE_SPELLING', 'GERMAN')
exec ctx_ddl.set_attribute('test', 'BASE_LETTER', 'TRUE')
exec ctx_ddl.set_attribute('test', 'OVERRIDE_BASE_LETTER', 'TRUE')

create index fooindex on foo(text) indextype is ctxsys.context
parameters ('lexer test');

create index fooindex2 on foo2(text) indextype is ctxsys.context
parameters ('lexer test');

select token_text from dr$fooindex$i;
select token_text from dr$fooindex2$i;

select * from foo where contains (text, 'schoen') > 0;
select * from foo where contains (text, 'schön') > 0;

select * from foo2 where contains (text, 'schoen') > 0;
select * from foo2 where contains (text, 'schön') > 0;
