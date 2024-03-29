connect system/oracle

alter system set events '30579 trace name context forever, level 2'; 

connect roger/roger

drop table foo;
create table foo( text varchar2(2000) );
insert into foo values ('hello world');

exec ctx_ddl.drop_preference('mystore')
exec ctx_ddl.create_preference('mystore', 'basic_storage')

exec ctx_ddl.set_attribute('mystore', 'big_io', 'true')

drop index fooindex;

create index fooindex on foo(text) indextype is ctxsys.context
parameters ('storage mystore')
/
