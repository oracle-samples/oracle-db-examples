set echo on

drop table krtest;
create table krtest (text varchar2(2000));
insert into krtest values ('ItemTranslate_ko');
exec ctx_ddl.drop_preference('krlex')
exec ctx_ddl.create_preference('krlex', 'KOREAN_MORPH_LEXER')
create index krindex on krtest(text)
indextype is ctxsys.context
parameters ('lexer krlex')
/
select token_text from dr$krindex$i;
select * from krtest where contains (text, 'itemtranslate\_ko') > 0;
select * from krtest where contains (text, 'itemtranslate ko') > 0;
