drop table foo;

create table foo (bar varchar2(200));

insert into foo values ('the cat sat on the mat');

exec ctx_ddl.drop_stoplist('foostop')
exec ctx_ddl.create_stoplist('foostop', 'basic_stoplist')
exec ctx_ddl.add_stopword('foostop', 'the')
exec ctx_ddl.add_stopword('foostop', 'on')

create index fooindex on foo (bar) indextype is ctxsys.context
parameters ('stoplist foostop');

select token_text from dr$fooindex$i;

-- this won't work (stopword only)
select * from foo where contains (bar, 'the') > 0;

-- this will work, "any word" is substituted for stopword in the phrase
select * from foo where contains (bar, 'sat on the mat') > 0;

exec ctx_ddl.remove_stopword('foostop', 'the')

alter index fooindex parameters('replace metadata stoplist foostop');

select * from foo where contains (bar, 'the') > 0;

insert into foo values ('the king and I');

exec ctx_ddl.sync_index ('fooindex')

select token_text from dr$fooindex$i;

-- We only get the new record
select * from foo where contains (bar, 'the') > 0;

-- This won't work because "the" is no longer a stopword, but it's also not indexed
select * from foo where contains (bar, 'sat on the mat') > 0;

-- But this will, because "on" is still a stopword and matches any word
select * from foo where contains (bar, 'sat on on mat') > 0;

