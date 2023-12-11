drop table t;

create table t(x varchar2(2000));

insert into t values ('the quick brown antelope voraciously consumes the angry dog');

exec ctx_ddl.drop_preference  ('wrd')
exec ctx_ddl.create_preference('wrd', 'BASIC_WORDLIST')
exec ctx_ddl.set_attribute    ('wrd', 'SUBSTRING_INDEX', 'Y')

exec ctx_ddl.drop_stoplist    ('stp')
exec ctx_ddl.create_stoplist  ('stp')
exec ctx_ddl.add_stopclass    ('stp', 'teststp', 'vor[^ ]*')
create index ti on t(x) indextype is ctxsys.context
parameters ('wordlist wrd stoplist stp')
/

select * from dr$ti$p
order by pat_part1;
