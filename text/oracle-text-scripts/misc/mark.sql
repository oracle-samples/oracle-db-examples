drop table foo;

create table foo (name varchar2(2000), address varchar2(2000), phone varchar2(2000));

insert into foo values ('Mark Drake', '201 Ford Street', '0123 4567');
insert into foo values ('Roger Ford', '123 Drake Terrace', '0123 7654');

exec ctx_ddl.drop_preference('mymcds')
exec ctx_ddl.create_preference('mymcds', 'multi_column_datastore')
exec ctx_ddl.set_attribute('mymcds', 'columns', 'name, address, phone')

create index fooindex on foo(name)
indextype is ctxsys.context
parameters ('datastore mymcds section group ctxsys.auto_section_group');


column name format a20
column address format a20
column phone format a20

select * from foo where contains (name, 'Drake')>0;

select * from foo where contains (name, 'Drake within name')>0;


