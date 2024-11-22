drop table oo_test;
create table oo_test (fname varchar2(255));

--insert into oo_test values ('e:\hello.txt');
insert into oo_test values ('e:\qbfox.sxw');
insert into oo_test values ('e:\revenues.sxc');

exec ctx_ddl.drop_preference('oo_filter')
exec ctx_ddl.create_preference('oo_filter', 'user_filter')
exec ctx_ddl.set_attribute('oo_filter', 'command', 'ooffice_filt.bat')

exec ctx_ddl.drop_section_group('oo_sg')
exec ctx_ddl.create_section_group('oo_sg', 'xml_section_group')

create index oo_test_index on oo_test (fname)
indextype is ctxsys.context
parameters ('datastore ctxsys.file_datastore filter oo_filter section group oo_sg')
/

select err_text from ctx_user_index_errors where err_index_name = 'oo_test_index'
/

select token_text from dr$oo_test_index$i;
