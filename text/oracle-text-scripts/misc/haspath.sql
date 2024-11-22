drop table t;
create table t(c varchar2(100));
insert into t values ('<>dog <fTargetGUID>shortcut fibble</fTargetGUID>');
insert into t values ('<>dog');
exec ctx_ddl.drop_section_group('mysg')
exec ctx_ddl.create_section_group('mysg', 'PATH_SECTION_GROUP')

create index i on t(c) indextype is ctxsys.context parameters ('section group mysg');

select * from t where contains(c, '(dog) NOT (HASPATH(//fTargetGUID))') > 0;
