drop table mynames;
exec ctx_ddl.drop_preference('my_multistore');
exec ctx_ddl.drop_section_group('my_sections');
set echo on

create table mynames (firstName varchar2(20), lastName varchar2(20));
insert into mynames values ('Bob', 'Smith');
insert into mynames values ('Bobby', 'Smithe');
insert into mynames values ('Bobby', 'Johnson');
insert into mynames values ('John',  'Smith');
exec ctx_ddl.create_preference('my_multistore', 'multi_column_datastore')
exec ctx_ddl.set_attribute('my_multistore', 'columns', 'firstname, lastname, firstname || lastname AS name')
exec ctx_ddl.create_section_group('my_sections', 'basic_section_group')
exec ctx_ddl.add_field_section('my_sections', 'firstname', 'firstname')
exec ctx_ddl.add_field_section('my_sections', 'lastname',  'lastname')
exec ctx_ddl.add_ndata_section('my_sections', 'name',      'name')
create index mynames_index on mynames(firstname) indextype is ctxsys.context
parameters ('datastore my_multistore section group my_sections');
select * from mynames where contains (firstname, 'NDATA(name, bob) OR Smith within lastname') > 0;
