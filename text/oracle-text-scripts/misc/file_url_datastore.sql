drop table testtable;
create table testtable (url varchar2(2000));

insert into testtable values ('file:///mnt/h/Temp/demo.sql');

exec ctx_ddl.drop_preference('my_uds')
exec ctx_ddl.create_preference('my_uds', 'URL_DATASTORE')

create index testindex on testtable (url) indextype is ctxsys.context
parameters ('datastore my_uds');

select * from ctx_user_index_errors;
