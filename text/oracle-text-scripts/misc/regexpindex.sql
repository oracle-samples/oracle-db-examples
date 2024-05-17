drop table test_prod;

create table test_prod (col1 varchar2(30));
insert into test_prod values ('01011967');
insert into test_prod values ('01-01-1967');
insert into test_prod values ('01 01 1967');

begin
ctx_ddl.drop_preference('my_lexer');
end;
/
begin
ctx_ddl.create_preference('my_lexer','BASIC_LEXER');
end;
/

begin
ctx_ddl.drop_preference('my_ds');
end;
/
begin
ctx_ddl.create_preference('my_ds', 'MULTI_COLUMN_DATASTORE');
ctx_ddl.set_attribute('my_ds', 'columns', 'regexp_replace(col1, ''[^0-9]'','''')');
end;
/

create index test_prod_idx on test_prod (col1)
indextype is ctxsys.context
parameters('lexer my_lexer datastore my_ds');

select *
from test_prod
where contains(col1, '01011967') >0;
