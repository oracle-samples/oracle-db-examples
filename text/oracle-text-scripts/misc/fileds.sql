-- Run this as CTXSYS or other DBA if you want to create the user first

drop user test_user cascade;
create user test_user identified by test_user;
grant connect,resource,ctxapp to test_user;

connect test_user/test_user

create table fileds (pk number primary key, filename varchar2(100));

insert into fileds values (1, 'hello.txt');
commit;

exec ctx_ddl.create_preference ('my_file_datastore', 'file_datastore');
exec ctx_ddl.set_attribute ('my_file_datastore', 'PATH', '/tmp');

create index fileds_index on fileds(filename)create index fileds_index on fileds(filename)
indextype is ctxsys.context
parameters ('datastore my_file_datastore');

select * from ctx_user_index_errors;

indextype is ctxsys.context
parameters ('datastore my_file_datastore');

select * from ctx_user_index_errors;

select pk, filename from fileds where contains (filename, 'hello') > 0;

--delete from dr$object where obj_name = 'FILE_DATASTORE';
