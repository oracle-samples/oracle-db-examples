-- NLS_LANG=GERMAN_GERMANY.WE8ISO8859P1
--alter session set NLS_LANGUAGE=GERMAN;
--alter session set NLS_TERRITORY=GERMANY;

drop table quick;

create table quick (
id number not null primary key,
text varchar2(40));

insert into quick values ( 1,'äpfel');
commit;

exec  ctx_ddl.drop_preference           ('WS_LEXER');
exec  ctx_ddl.create_preference         ('WS_LEXER','BASIC_LEXER' );
exec  ctx_ddl.set_attribute             ('WS_LEXER','INDEX_TEXT','TRUE');
exec  ctx_ddl.set_attribute             ('WS_LEXER','INDEX_THEMES','FALSE');
exec  ctx_ddl.set_attribute             ('WS_LEXER','MIXED_CASE','NO');
exec  ctx_ddl.set_attribute             ('WS_LEXER','ALTERNATE_SPELLING','GERMAN');
exec  ctx_ddl.set_attribute             ('WS_LEXER','BASE_LETTER','NO');

create index quick_ctx on quick( text )
  indextype is ctxsys.context
  parameters ('lexer ws_lexer') ;

SQL> select token_text from dr$quick_ctx$I;
 
select id from quick where contains ( text, 'äpfel')>0;

select id from quick where contains ( text, 'aepfel')>0;
 
select id from quick where contains ( text, 'äpf%')>0;
