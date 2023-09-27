connect roger/roger

drop table foo;
create table foo (bar varchar2(200), baz varchar2(200));

insert into foo values ('hello', 'world');

exec ctx_ddl.drop_preference('mymcds')
exec ctx_ddl.create_preference('mymcds', 'multi_column_datastore')
exec ctx_ddl.set_attribute('mymcds', 'columns', 'bar,baz')

exec ctx_ddl.drop_section_group('mysg')
exec ctx_ddl.create_section_group('mysg', 'basic_section_group')
exec ctx_ddl.add_field_section('mysg', 'bar', 'bar', false)
exec ctx_ddl.add_field_section('mysg', 'baz', 'baz', false)

create index fooindex on foo(bar) indextype is ctxsys.context
parameters ('datastore mymcds section group mysg');

column token_text format a30

select token_type, token_text from dr$fooindex$i;

connect system/oracle
alter system set sql_trace=true;
connect roger/roger

select rowid from foo where contains (bar, 'fuzzy(hello) within bar') > 0;

connect system/oracle
alter system set sql_trace=false;
