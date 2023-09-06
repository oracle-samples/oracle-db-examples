-- use the multi_column_datastore to remove spaces
-- from a column contents before indexing

drop table foo;
exec ctx_ddl.drop_preference('unspace_datastore')

create table foo (textcol varchar2(30));

insert into foo values ('Vandeberg');
insert into foo values ('Van de berg');
insert into foo values ('Van deberg');
insert into foo values ('Vande berg');

exec ctx_ddl.create_preference('unspace_datastore', 'multi_column_datastore')
exec ctx_ddl.set_attribute('unspace_datastore', 'columns', 'replace(textcol, '' '', '''')')

create index fooindex on foo (textcol) indextype is ctxsys.context parameters('datastore unspace_datastore');

select textcol from foo where contains (textcol, 'vandeberg') > 0;
