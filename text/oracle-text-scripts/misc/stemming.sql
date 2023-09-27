drop table mystemming;

create table mystemming (pk number primary key, text varchar2(60));
insert into mystemming values (1, 'swimming');
insert into mystemming values (2, 'running');
insert into mystemming values (3, 'climbing');
commit;

exec ctx_ddl.drop_preference  ('lex')
exec ctx_ddl.create_preference('lex', 'BASIC_LEXER')
exec ctx_ddl.set_attribute    ('lex', 'INDEX_STEMS', 'ENGLISH')

create index mystemming_index on mystemming (text)
indextype is ctxsys.context
parameters ('lexer lex');

select token_text,token_type from dr$mystemming_index$i;

select * from mystemming where contains (text, '$runs') > 0;


