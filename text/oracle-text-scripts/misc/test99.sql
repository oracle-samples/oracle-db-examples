drop table books;
exec ctx_ddl.drop_preference('imtlexer')

create table books
(
books_id number
constraint books_pk primary key,
price number,
title varchar2(80)
);

insert into books
values ( 1, 10, 'The cat sat on the mat.' );
insert into books
values ( 2, 12, 'The quick brown fox jumps over the lazy dog. woof' );
insert into books
values ( 3, 15, 'The dog barked like a dog.' );
commit;

BEGIN
ctx_ddl.create_preference ('imtlexer','basic_lexer');
ctx_ddl.set_attribute ('imtlexer','index_themes','no');
ctx_ddl.set_attribute('imtlexer', 'punctuations', ',');
ctx_ddl.set_attribute('imtlexer', 'printjoins', '-,/.''');
END;
/

create index books_title on books ( title )
indextype is ctxsys.context parameters('lexer IMTLEXER');

select token_text from DR$books_title$I;

select title from books
where contains ( title, 'dog.%' ) > 0;
