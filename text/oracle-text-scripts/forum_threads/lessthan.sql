--drop table xyz;
==create table xyz(value varchar2(2000));
--insert into xyz values ('<Term> 30 with< Characters>');

drop index xyzi;
exec ctx_ddl.drop_preference  ('mylex')
exec ctx_ddl.create_preference('mylex', 'BASIC_LEXER')
exec ctx_ddl.set_attribute    ('mylex', 'PRINTJOINS', '><')
create index xyzi on xyz(value) indextype is ctxsys.context parameters ('lexer mylex');
select * from xyz where contains(value, '\<Term\> 30 with\< Characters\>', 1) > 0;
select * from xyz where contains(value, 'Term 30 with Characters', 1) > 0;
select * from xyz where contains(value, '\>Term\< \<30\> \>with\< Characters\>\>\>', 1) > 0;
