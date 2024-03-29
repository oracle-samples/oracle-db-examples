-- json_textcontains returns rows for the textual word 'null'
-- where an array entry is null. This is not correct behavior but is
-- seen as an edge case

drop table foo;

create table foo(bar blob, constraint barisjson check (bar is json));

insert into foo values ( '{ "myarray":["abc", 1, NULL] }' );

create search index fooindex on foo(bar) for json;

-- check tokens in index
column token_text format a30
select token_text, token_type from dr$fooindex$i;

-- matches
select json_serialize(bar) from foo where json_textcontains(bar, '$.myarray', 'a%');

-- doesn't match
select json_serialize(bar) from foo where json_textcontains(bar, '$.myarray', 'b%');

-- does match but should not
select json_serialize(bar) from foo where json_textcontains(bar, '$.myarray', 'null');
