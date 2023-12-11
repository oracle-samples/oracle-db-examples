-- drop table foo;

create table foo(bar varchar2(2000) check (bar is json));

insert into foo values ('{ "pangram": "the quick brown fox jumps over the lazy dog" }');

-- exec ctx_ddl.drop_preference  ('wildcard_pref')
exec ctx_ddl.create_preference('wildcard_pref', 'BASIC_WORDLIST')
exec ctx_ddl.set_attribute    ('wildcard_pref', 'WILDCARD_INDEX', 'T')

create search index fooindex on foo(bar) for json
parameters ('wordlist wildcard_pref');

-- don't need wildcard index for non-wildcard search or trailing wildcard
select * from foo 
where json_textcontains (bar, '$.pangram', 'brow%');

-- do need it for good performance on leading wildcards
select * from foo 
where json_textcontains (bar, '$.pangram', '%rown');


