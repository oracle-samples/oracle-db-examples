drop table foo;

create table foo (text varchar2(2000));

insert into foo values ('dog <action>jump</jump>');
insert into foo values ('dog <action>sit</jump>');
insert into foo values ('cat <action>jump</jump>');
insert into foo values ('cat <action>sit</jump>');

exec ctx_ddl.drop_stoplist('s')
exec ctx_ddl.create_stoplist('s', 'BASIC_STOPLIST')
exec ctx_ddl.add_stopword('s', 'jump')

exec ctx_ddl.drop_section_group('sg')
exec ctx_ddl.create_section_group('sg', 'AUTO_SECTION_GROUP')

create index fooind on foo(text) indextype is ctxsys.context
parameters ('stoplist s section group sg');

select * from foo where contains (text, 'dog and (jump within action)') > 0;
select * from foo where contains (text, 'dog and (jump within action)') > 0;
select * from foo where contains (text, 'dog and (sit within action)') > 0;
