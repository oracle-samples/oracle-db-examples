-- must do GRANT EXECUTE ON CTX_THES TO <username>

@parser_fuzzy.pls

-- clear the thesaurus name for repeated runs

exec parser.setThesName('')

exec ctx_thes.drop_thesaurus('mythes')

exec ctx_thes.create_thesaurus('mythes')

exec ctx_thes.create_relation('mythes', 'quick', 'SYN', 'speedy')
exec ctx_thes.create_relation('mythes', 'quick', 'SYN', 'fast')

drop table testtab;
create table testtab (text varchar2(2000));

insert into testtab values ('the quick brown fox jumps over the lazy dog');
insert into testtab values ('the fast brown fox jumps over the lazy dog');

create index testindex on testtab(text) indextype is ctxsys.context parameters ('sync(on commit)');

-- will only find the second row

select * from testtab where contains( text, parser.simplesearch('+fast brown dog')) > 0;

-- now set the thesaurus and it will find both rows

exec parser.setThesName('mythes')

select * from testtab where contains( text, parser.simplesearch('+fast brown dog')) > 0;

-- show fuzzy. First no match with +broon

select * from testtab where contains( text, parser.simplesearch('+fast +broon dog')) > 0;

-- but if we use fuzzy on it we get a match

select * from testtab where contains( text, parser.simplesearch('+fast +?broon dog')) > 0;
