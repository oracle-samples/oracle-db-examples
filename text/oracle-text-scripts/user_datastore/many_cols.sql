-- code sample showing text index on multiple fields in a table using 
-- a USER_DATASTORE procedure
-- we translate spaces into % signs so columns get indexed as a single string
-- a more thorough technique would be to use APEX_UTIL.URL_ENCODE so we 
-- can have other characters encoded

drop table mytable;

create table mytable
  ( code varchar2(2),
    author varchar2(50),
    price number);

create table debug (text varchar2(2000));

insert into mytable values ('ab', 'John Smith', 20);
insert into mytable values ('cd', 'Peter John Blythe', 100);
insert into mytable values ('ef', 'Fred Flintstone', '750');

create or replace procedure myproc (
  rid rowid,
  outclob in out nocopy clob) is
begin
  -- note this loop gets executed once only
  for c in (select code, author, price
            from mytable
	    where rowid = rid) loop
    outclob :=            ' code='   || c.code;
    outclob := outclob || ' author=' || translate(c.author, ' ', '%');
    outclob := outclob || ' price='  || c.price;
    insert into debug values (outclob);
  end loop;
end;
/
list
show errors

-- A virtual document is produced which contains something like:
-- code=20
-- author=Roger%Ford
-- price=100

exec ctx_ddl.drop_preference('myds')
exec ctx_ddl.create_preference('myds', 'USER_DATASTORE')
exec ctx_ddl.set_attribute('myds', 'PROCEDURE', 'myproc')

-- make sure % and = is indexed as part of a word
exec ctx_ddl.drop_preference('mylex')
exec ctx_ddl.create_preference('mylex', 'BASIC_LEXER')
exec ctx_ddl.set_attribute('mylex', 'PRINTJOINS', '%=')

-- doesn't matter which column we actually create the index on
-- all the data is pulled in by the datastore procedure

create index myindex on mytable(code)
indextype is ctxsys.context
parameters ('datastore myds lexer mylex');

-- show the indexed tokens
select token_text from dr$myindex$i;


-- now do searches
select * from mytable where contains(code, '{author=Fred%Flintstone}') > 0;

select * from mytable where contains(code, '{code=ab} AND {author=John%Smith}') > 0;

select * from mytable where contains(code, '{code=ab} OR {price=750}') > 0;

