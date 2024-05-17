set timing on

drop table items;
 
create table items (
   "ITEM_NAME"                varchar2(100 byte),
    "ITEM_NUMBER"              varchar2(100 byte),
    "DESCRIPTION"              varchar2(4000 byte),
    "OWNER" number
);
/ 
 
begin
  FOR Lcntr IN 1..100000
  loop
     insert into items (item_name, item_number, description, owner) values (dbms_random.string('A', 10), dbms_random.string('A', 10), dbms_random.string('L', 8) || ' ' || dbms_random.string('A', 4) || dbms_random.string('A', 5)  || ' ' || dbms_random.string('A', 10), dbms_random.value(1,10) );
  end loop;
end;
/ 
 
begin
  FOR Lcntr IN 1..100000
  loop
     insert into items (item_name, item_number, description, owner) values (dbms_random.string('A', 10), dbms_random.string('A', 10), dbms_random.string('L', 8) || ' ' || dbms_random.string('A', 4) || '111'  || dbms_random.string('A', 5)  || ' ' || dbms_random.string('A', 10), 1234 );
  end loop;
end;
/ 
 
commit;
 
execute ctx_ddl.drop_preference('ENG_WORDLIST');
execute ctx_ddl.create_preference('ENG_WORDLIST', 'BASIC_WORDLIST');
execute ctx_ddl.set_attribute('ENG_WORDLIST','PREFIX_INDEX','TRUE');
execute ctx_ddl.set_attribute('ENG_WORDLIST','PREFIX_MIN_LENGTH',1);
execute ctx_ddl.set_attribute('ENG_WORDLIST','PREFIX_MAX_LENGTH',10);
execute ctx_ddl.set_attribute('ENG_WORDLIST','SUBSTRING_INDEX','TRUE');
execute ctx_ddl.set_attribute('ENG_WORDLIST','WILDCARD_MAXTERMS', 0);
 
-- Create a lexer based on basic_lexer
execute ctx_ddl.drop_preference('ENG_LEXER');
EXECUTE CTX_DDL.CREATE_PREFERENCE ('ENG_LEXER', 'BASIC_LEXER');
 
-- set special characters "@-_" as part of the words when they get indexed.
EXECUTE CTX_DDL.SET_ATTRIBUTE ('ENG_LEXER', 'PRINTJOINS', '@-_');
 
execute ctx_ddl.drop_preference('item_mult_preference');
 
execute ctx_ddl.create_preference('items_multi_preference', 'MULTI_COLUMN_DATASTORE');
execute ctx_ddl.set_attribute('items_multi_preference', 'columns', 'item_name, description,item_number');
 
drop index items_text_index;
create index items_text_index on items(description) indextype is ctxsys.context filter by owner parameters('LEXER ENG_LEXER WORDLIST ENG_WORDLIST STOPLIST CTXSYS.EMPTY_STOPLIST datastore items_multi_preference MEMORY 1024M') ;
 
--it takes 600 seconds returning zero count.
select count(*) from items where contains (description, '%111%') > 0 and owner = 12345;
 
--it takes less than 1 second
select count(*) from items where contains (description, '111%') > 0 and owner = 12345;
