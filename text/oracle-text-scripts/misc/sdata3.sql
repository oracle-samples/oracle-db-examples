set echo on

drop table foo;

create table foo (text varchar2(2000));

insert into foo values ('<category>car truck motorcycle</category>');

exec ctx_ddl.drop_section_group('mysec')
exec ctx_ddl.create_section_group('mysec', 'BASIC_SECTION_GROUP')
exec ctx_ddl.add_sdata_section('mysec', 'category', 'category')

create index fooindex on foo (text) indextype is ctxsys.context 
parameters ('section group mysec');

select * from foo where contains( text, 'sdata(category like ''%truck%'')' ) > 0;
