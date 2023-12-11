-- demonstrate the use of ALTERNATE_SPELLING in Oracle Text
-- the German language treats certain combinations of letters as equivalent to
--  certain accented characters
-- with correct settings, Oracle Text will allow you to search using one form and find the other
-- If running this from SQL*Plus you will need to set NLS_LANG correctly to allow for multibyte chars::
-- export NLS_LANG=German_germany.al32utf
-- or in csh
-- setenv NLS_LANG German_germany.al32utf

-- this testcase uses 'sharp S' (scharfes S) which may be substitutes with 'ss'
-- and u-umlaut which may be substituted with 'ue'

set echo on

spool german_alternate_spelling.log

drop table altspell;

create table altspell (text varchar2(2000));

insert into altspell values (unistr('Die Katze ist auf der Strasse'));
insert into altspell values ('Ich liebe Muenchen');

select * from altspell;

exec ctx_ddl.drop_preference('mylex')
exec ctx_ddl.create_preference('mylex', 'BASIC_LEXER')

exec ctx_ddl.set_attribute('mylex', 'ALTERNATE_SPELLING', 'GERMAN')
exec ctx_ddl.set_attribute('mylex', 'MIXED_CASE', 'TRUE')

create index altspellindex on altspell (text)
indextype is ctxsys.context
parameters ('lexer mylex');

select * from altspell where contains (text, 'Straẞe') > 0;
select * from altspell where contains (text, 'München') > 0;

-- check what tokens were indexed
select token_text from dr$altspellindex$i;

spool off
