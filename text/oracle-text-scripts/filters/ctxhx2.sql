-- ctxhx2 is the new filtering architecture in 23c.
-- in initial release it is hidden under an event

connect sys/oracle as sysdba
-- event to turn it on: Event 30583 level 1:  Enable ctxhx2
alter system set events '30583 trace name context forever, level 1';

connect roger/roger

drop table docs;
create table docs(filename varchar2(2000));

insert into docs values ('/mnt/Dropbox/docs/HelloWorld.docx');

create index docsindex on docs(filename)
indextype is ctxsys.context
parameters ('datastore ctxsys.file_datastore')
/

select * from ctx_user_index_errors where err_index_name = 'DOCSINDEX';

select * from docs where contains(filename, 'hello') > 0;
