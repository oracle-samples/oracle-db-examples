drop table mytable;
create table mytable (pk number primary key, text varchar2(4000));

insert into mytable values (1, '<BOOK TITLE="software"><CHAPTER>hello world</CHAPTER></BOOK>');
commit;

exec ctx_ddl.drop_section_group ('my_section_group');
exec ctx_ddl.create_section_group ('my_section_group', 'AUTO_SECTION_GROUP');

create index mytableindex on mytable (text) indextype is ctxsys.context
parameters ('section group my_section_group');

select text from mytable where contains (text,
'( (hello within chapter) and software within book@title ) within book') > 0;

