create table pruebatext_test (
  code number primary key,
  col1 varchar2(300) not null,
  col2 clob not null);

insert into pruebatext_test values (1, 'hola', 'bien');
commit;

exec ctx_cd.drop_cdstore('my_cdstore')
exec ctx_cd.Create_CDstore('my_cdstore', 'pruebatext_test')
exec ctx_cd.Add_Column    ('my_cdstore', 'col1')
exec ctx_cd.Add_Column    ('my_cdstore', 'col2');

CREATE INDEX myindex ON pruebatext_test(col1) INDEXTYPE IS ctxsys.context
    PARAMETERS ('datastore my_cdstore section group my_cdstore');

exec ctx_cd.Add_Update_Trigger('my_cdstore', 'col1');

SELECT code, col1 FROM pruebatext_test
WHERE CONTAINS (col1,
'hola within col1 and bien within col2') > 0;

