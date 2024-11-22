drop table t;
create table t (id number primary key, text varchar2(2000));

insert into t values (1, '
<DOC DOCUMENT_ID="123456" DOCST="ACTIVE">
<DOCTYPE>PHOTO</DOCTYPE>
</DOC>
');

insert into t values (2, '
<DOC DOCUMENT_ID="123457" DOCST="CANCEL">
<DOCTYPE>PHOTO</DOCTYPE>
</DOC>
');

create index ti on t(text) indextype is ctxsys.context
parameters ('section group ctxsys.auto_section_group');

select id from t where contains (text, '(photo within doctype) not (active within doc@docst)') > 0;

select id from t where contains (text, '(photo within doctype) and ((cancel or delete) within doc@docst)') > 0;


