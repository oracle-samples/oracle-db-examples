drop table mytable;

create table mytable (text varchar2(2000));

insert into mytable values ('grace');
insert into mytable values ('granted');
insert into mytable values ('gravel');
insert into mytable values ('grand');

exec ctx_ddl.drop_preference('mylexer')

exec ctx_ddl.create_preference('mylexer', 'basic_lexer')

exec ctx_ddl.drop_preference('mywordlist')

exec ctx_ddl.create_preference('mywordlist', 'basic_wordlist')
exec ctx_ddl.set_attribute('mywordlist', 'prefix_index', 'true')
-- exec ctx_ddl.set_attribute('mywordlist', 'substring_index', 'true')
exec ctx_ddl.set_attribute('mywordlist', 'wildcard_maxterms', '3')

create index myindex on mytable (text) indextype is ctxsys.context
parameters ('lexer mylexer wordlist mywordlist');

set echo on

select token_type, token_text from dr$myindex$i order by token_type;

column pat_part1 format a20
column pat_part2 format a20

select pat_part1, pat_part2 from dr$myindex$p;

select * from mytable where contains (text, 'gra%') > 0;
