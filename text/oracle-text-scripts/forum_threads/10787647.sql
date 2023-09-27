drop table names;
create table names (id number primary key, text varchar2(50));

insert into names values( 1, 'just and kind, kind and loving' );
insert into names values( 2, 'just, kind' );

exec ctx_ddl.drop_preference  ( 'mylex' )
exec ctx_ddl.create_preference( 'mylex', 'BASIC_LEXER' )
exec ctx_ddl.set_attribute    ( 'mylex', 'PUNCTUATIONS', ',' )

exec ctx_ddl.drop_preference  ( 'mcds' )
exec ctx_ddl.create_preference( 'mcds',  'MULTI_COLUMN_DATASTORE' )
exec ctx_ddl.set_attribute    ( 'mcds', 'COLUMNS', '''XX1 ''||replace(text, '','',''XX2, XX1'')||'' XX2''' )

exec ctx_ddl.drop_preference  ( 'mywl' )
exec ctx_ddl.create_preference( 'mywl', 'BASIC_WORDLIST' )
exec ctx_ddl.set_attribute    ( 'mywl', 'SUBSTRING_INDEX', 'YES' )

create index namesindex on names(text)
indextype is ctxsys.context
parameters( 'datastore mcds wordlist mywl' )
/

select score(1),id,text from names where contains( text, '
<query>
  <textquery>
    <progression>
      <seq> XX1 kind XX2 </seq>
      <seq> kind</seq>
    </progression>
  </textquery>
</query>
', 1) > 0 
order by score(1) desc
/
