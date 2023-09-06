drop table foo;

create table foo(id number, text varchar2(4000), col1 varchar2(30), col2 varchar2(30), col3 date);

insert into foo values (1, 'hello world', 'fred', 'john', sysdate);

exec ctx_ddl.drop_section_group    ('mysg')
exec ctx_ddl.create_section_group ('mysg', 'BASIC_SECTION_GROUP')

create index fooindex on foo(text) indextype is ctxsys.context
filter by col1, col2, col3
parameters ('section group mysg')
/


select * from foo where contains( text, 'hello and sdata(col1=''fred'')') > 0
/
