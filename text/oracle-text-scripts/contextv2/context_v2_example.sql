-- if you use create search index syntax it's equivalent to using
-- indextype contextv2
-- search index for JSON is available in 19c
-- search index for text requires 21c or later

drop table foo;

create table foo(bar varchar2(2000));

insert into foo values ('hello world');

-- these two are equivalent. 1/ Using indextype context_v2
create index fooindex on foo(bar) indextype is ctxsys.context_v2;

select index_name, index_type from user_indexes where index_name = 'FOOINDEX';

drop index fooindex;

-- and 2/ using 'search index'
create search index fooindex on foo(bar);

select index_name, index_type from user_indexes where index_name = 'FOOINDEX';

select * from foo where contains (bar, 'hello') > 0;

-- now a JSON search index

drop table foo;

create table foo(bar varchar2(2000) check (bar is json));

insert into foo values ('{ "salutation": "hello", "audience": "world" }');

create search index fooindex on foo(bar) for json;

select * from foo where json_textcontains(bar, '$.salutation', 'hello');

-- drop index fooindex;

set linesize 132
set trimspool on
set long 500000

select ctx_report.create_index_script('fooindex') from dual;

-- the CONTEXTV2 syntax for JSON is more complex and not recommended for use
-- as you must manually set various PARAMETERS clauses for JSON processing
