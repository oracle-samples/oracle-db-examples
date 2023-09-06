drop table testtable;

create table testtable (text varchar2(200));

insert into testtable values ('cat <seca>dog</seca>');
insert into testtable values ('cat');

exec ctx_ddl.drop_section_group('sg')
exec ctx_ddl.create_section_group('sg', 'basic_section_group')
exec ctx_ddl.add_field_section('sg', 'seca', 'seca')

create index testindex on testtable(text)
indextype is ctxsys.context 
parameters ('section group sg');

select text from testtable where contains (text, '(dog WITHIN seca)') > 0;

select text from testtable where contains (text, 'cat & ((({dog})) WITHIN seca)') > 0;
select text from testtable where contains (text, '((({cat}),(((({dog})&{dog})) WITHIN seca))&((({dog})) WITHIN seca))') > 0;
select text from testtable where contains (text, '(cat,((dog) WITHIN seca) & (dog WITHIN seca) )') > 0;
