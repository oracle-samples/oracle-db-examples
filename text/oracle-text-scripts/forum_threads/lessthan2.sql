drop table xyz;
create table xyz(value varchar2(2000));
insert into xyz values ('BN.TermFinal_EUC Glossary.test %.01');
drop index xyzi;
exec ctx_ddl.drop_preference  ('mylex')
exec ctx_ddl.create_preference('mylex', 'BASIC_LEXER')
exec ctx_ddl.set_attribute    ('mylex', 'PRINTJOINS', '><_')
create index xyzi on xyz(value) indextype is ctxsys.context parameters ('lexer mylex');
select token_text from dr$xyzi$i;
select * from xyz where contains(value, 'BN.TermFinal_EUC Glossary.test', 1) > 0;
select * from xyz where contains(value, 'BN.TermFinal_EUC', 1) > 0;
select * from xyz where contains(value, '\%.01', 1) > 0;
select * from xyz where contains(value, 'BN.TermFinal_EUC Glossary.test \%.01', 1) > 0;

