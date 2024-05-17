connect / as sysdba

create or replace directory dirstore_docs as '/mnt/Dropbox/docs';

grant read on dirstore_docs to roger;

connect roger/roger

drop table docs;

create table docs (filename varchar2(50));

insert into docs values ('index.sql');
insert into docs values ('ReleaseNotes.pdf');

exec ctx_ddl.drop_preference  ('mydirstore')
exec ctx_ddl.create_preference('mydirstore', 'DIRECTORY_DATASTORE')
exec ctx_ddl.set_attribute    ('mydirstore', 'DIRECTORY', 'DIRSTORE_DOCS')

create index docsindex on docs(filename)
indextype is ctxsys.context
parameters ('datastore mydirstore')
/

select * from ctx_user_index_errors where err_index_name = 'DOCSINDEX';
