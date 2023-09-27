drop table my_table
/
create table my_table( text varchar2(2000) )
/

insert into my_table values( 'the quick brown fox jumps over the lazy dog' )
/
insert into my_table values( 'Mr. Brown jumsp over the lazy dog' )
/
insert into my_table values( 'BROWN is a colour' )
/

exec ctx_ddl.drop_preference      ( 'mylex' )
exec ctx_ddl.create_preference    ( 'mylex', 'BASIC_LEXER' )
exec ctx_ddl.set_attribute        ( 'mylex', 'MIXED_CASE', 'yes' )

exec ctx_ddl.drop_preference      ( 'myds' )
exec ctx_ddl.create_preference    ( 'myds', 'MULTI_COLUMN_DATASTORE' )
exec ctx_ddl.set_attribute        ( 'myds', 'COLUMNS', 'text, lower(text) as case_insens' )

exec ctx_ddl.drop_section_group   ( 'mysg' )
exec ctx_ddl.create_section_group ( 'mysg', 'BASIC_SECTION_GROUP' )
exec ctx_ddl.add_field_section    ( 'mysg', 'case_insens', 'case_insens', false )

create index my_index on my_table( text) indextype is ctxsys.context
parameters ( 'lexer mylex datastore myds section group mysg' )
/

set echo on

select * from my_table where contains( text, 'Brown' ) > 0;
select * from my_table where contains( text, 'brown within case_insens' ) > 0;
