drop table docs;

create table docs (filename varchar2(200));
insert into docs values ('/mnt/Dropbox/docs/README.pdf');
insert into docs values ('/mnt/Dropbox/docs/simpletable.docx');
insert into docs values ('/mnt/Dropbox/docs/David-Malpass.pdf');

exec ctx_ddl.drop_preference  ('docs_ds')
exec ctx_ddl.create_preference('docs_ds', 'FILE_DATASTORE')

exec ctx_ddl.drop_preference  ('docs_lx')
exec ctx_ddl.create_preference('docs_lx', 'BASIC_LEXER')
exec ctx_ddl.set_attribute    ('docs_lx', 'INDEX_THEMES', 't')

create index docsindex on docs (filename) 
indextype is ctxsys.context
parameters ('datastore docs_ds lexer docs_lx');

select * from ctx_user_index_errors where err_index_name = 'DOCSINDEX';
