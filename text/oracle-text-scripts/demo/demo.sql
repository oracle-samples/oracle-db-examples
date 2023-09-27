exec ctx_ddl.drop_preference   ('auto_lex')
exec ctx_ddl.create_preference ('autolex', 'AUTO_LEXER')
exec ctx_ddl.drop_policy       ('DEFAULT_POLICY')
exec ctx_ddl.create_policy     ('DEFAULT_POLICY', lexer=>'autolex')

drop table docs;

create table docs (filename varchar2(200));
insert into docs values ('/mnt/Dropbox/docs/README.pdf');
insert into docs values ('/mnt/Dropbox/docs/simpletable.docx');
insert into docs values ('/mnt/Dropbox/docs/David-Malpass.pdf');
insert into docs values ('/mnt/Dropbox/docs/David-Malpass-AR.pdf');
insert into docs values ('/mnt/Dropbox/docs/David-Malpass-GE.pdf');
insert into docs values ('/mnt/Dropbox/docs/David-Malpass-RU.pdf');

exec ctx_ddl.drop_preference  ('docs_ds')
exec ctx_ddl.create_preference('docs_ds', 'FILE_DATASTORE')

exec ctx_ddl.drop_section_group  ('docs_sg')
exec ctx_ddl.create_section_group('docs_sg', 'AUTO_SECTION_GROUP')

create index docsindex on docs (filename) 
indextype is ctxsys.context
parameters ('datastore docs_ds section group docs_sg');

select * from ctx_user_index_errors where err_index_name = 'DOCSINDEX';
