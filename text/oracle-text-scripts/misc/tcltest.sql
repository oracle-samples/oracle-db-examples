drop table tcltest;

exec ctx_ddl.drop_preference   ( 'mydatastore' );
exec ctx_ddl.drop_preference   ( 'myfilter'    );

create table tcltest (id number  primary key, 
                      filename   varchar2(80)
                     );

insert into tcltest values ( 1, 'G:\auser\doc\crowtree.doc' );
commit;

exec ctx_ddl.create_preference ( 'mydatastore', 'FILE_DATASTORE' );

exec ctx_ddl.create_preference ( 'myfilter',    'USER_FILTER'    );
exec ctx_ddl.set_attribute     ( 'myfilter',    'command',   'ctxFilterClient.bat' );

create index tclindex on tcltest (filename) indextype is ctxsys.context
parameters ('datastore mydatastore filter myfilter');


