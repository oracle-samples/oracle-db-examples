drop table mytable;

create table mytable (text varchar2(2000));

insert into mytable values ('oracle');
exec ctx_ddl.drop_preference('mywordlist')
exec ctx_ddl.create_preference('mywordlist', 'basic_wordlist')
exec ctx_ddl.set_attribute('mywordlist', 'substring_index', 'true')

create index myindex on mytable (text) indextype is ctxsys.context
parameters ('wordlist mywordlist');

set echo on

select token_type, token_text from dr$myindex$i order by token_type;

column pat_part1 format a20
column pat_part2 format a20

select pat_part1, pat_part2 from dr$myindex$p order by length(pat_part1);
