drop table t;
create table t(c varchar2(100));
insert into t values ('dog <fLinkType>shortcut fibble</fLinkType>');
insert into t values ('dog <fLinkType>fibble</fLinkType>');
exec ctx_ddl.drop_section_group('mysg')
exec ctx_ddl.create_section_group('mysg', 'BASIC_SECTION_GROUP')
exec ctx_ddl.add_field_section('mysg', 'fLinkType', 'fLinkType', false)

create index i on t(c) indextype is ctxsys.context parameters ('section group mysg');

select * from t where contains(c, '(dog) NOT (shortcut within fLinkType)') > 0;
