-- basic example of CTXCAT indextype
-- it uses an index_set with column CATEGORY in it, so we can include that in a CATSEARCH search
-- to a large extent the use of CONTEXT index with SDATA columns supercedes this useage.

set echo on

drop table mytable;
create table mytable( category varchar2(30), textcol varchar2(4000) );

exec ctx_ddl.drop_index_set( 'myis' )
exec ctx_ddl.create_index_set( 'myis' )
exec ctx_ddl.add_index( 'myis', 'CATEGORY' )

exec ctx_ddl.drop_preference('catlex')
exec ctx_ddl.create_preference('catlex', 'BASIC_LEXER')
exec ctx_ddl.set_attribute('catlex', 'PRINTJOINS', '-.')

create index catindex on mytable (textcol) 
indextype is ctxsys.ctxcat
parameters( 'index set myis lexer catlex' )
/

insert into mytable values ('books', 'The Grapes of Wrath')
/

insert into mytable values ('books', 'foo-doo')
/

select * from mytable where catsearch(textcol, 'grapes', 'category=''books''') > 0;

select * from mytable where catsearch(textcol, 'foo doo', 'category=''books''') > 0;

select * from mytable where catsearch(textcol, 'foo-doo', 'category=''books''') > 0;


exec ctx_ddl.set_attribute('catlex', 'PRINTJOINS', ':;')

alter index catindex rebuild parameters ('replace lexer catlex');

select * from mytable where catsearch(textcol, 'foo doo', 'category=''books''') > 0;

select * from mytable where catsearch(textcol, 'foo-doo', 'category=''books''') > 0;
