drop table example;
create table example(text varchar2(2000));

insert into example values ('Hello World ???');
insert into example values ('quick???');

exec ctx_ddl.drop_preference('mylexer')
exec ctx_ddl.create_preference('mylexer', 'BASIC_LEXER')
exec ctx_ddl.set_attribute('mylexer', 'PUNCTUATIONS', ' ')
exec ctx_ddl.set_attribute('mylexer', 'PRINTJOINS', '?')

create index exampleindex on example(text)
indextype is ctxsys.context 
parameters('lexer mylexer')
/
select token_text from dr$exampleindex$i;
