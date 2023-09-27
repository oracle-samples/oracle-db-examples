
set concat .
set trimspool on
set timing on
set time on
set verify off
set lin 200 echo on serveroutput on
define TABELLE=MYTABLE
define SPALTE=OTXML
define INDEXNAME=&&TABELLE._&&SPALTE
define TBSNAME=USERS
define MEMORY=100M

--
-- create test table
--

create table &&TABELLE (text clob,pool varchar2(10),otxml varchar2(3));
insert into &&TABELLE values ('my text','N',' ');
commit;

--
-- create text index on column OTXML
--
begin
  ctx_ddl.create_section_group('&&INDEXNAME._SG','XML_SECTION_GROUP');
  ctx_ddl.add_mdata_column('&&INDEXNAME._SG','POOL','POOL');
  ctx_ddl.add_field_section('&&INDEXNAME._SG','TEXT','TEXT',TRUE);
end;
/

begin
  ctx_ddl.create_preference('&&INDEXNAME._DS','MULTI_COLUMN_DATASTORE');
  ctx_ddl.set_attribute('&&INDEXNAME._DS','COLUMNS','TEXT');

  -- LEXER PREFERENCE
  ctx_ddl.create_preference('&&INDEXNAME._LX', 'BASIC_LEXER');
  ctx_ddl.set_attribute('&&INDEXNAME._LX', 'COMPOSITE','DEFAULT');
  ctx_ddl.set_attribute('&&INDEXNAME._LX', 'ALTERNATE_SPELLING', 'GERMAN');
  ctx_ddl.set_attribute('&&INDEXNAME._LX', 'OVERRIDE_BASE_LETTER', 'YES');
  ctx_ddl.set_attribute('&&INDEXNAME._LX', 'BASE_LETTER', 'YES');
  ctx_ddl.set_attribute('&&INDEXNAME._LX', 'INDEX_TEXT', 'YES');
  ctx_ddl.set_attribute('&&INDEXNAME._LX', 'INDEX_THEMES', 'NO');
  ctx_ddl.set_attribute('&&INDEXNAME._LX', 'MIXED_CASE', 'NO');
  ctx_ddl.set_attribute('&&INDEXNAME._LX', 'NUMJOIN', ',');
  ctx_ddl.set_attribute('&&INDEXNAME._LX', 'NUMGROUP','.');

  -- WORDLIST PREFERENCE
  ctx_ddl.create_preference('&&INDEXNAME._WL', 'BASIC_WORDLIST');
  ctx_ddl.set_attribute('&&INDEXNAME._WL', 'FUZZY_MATCH', 'GERMAN');
  ctx_ddl.set_attribute('&&INDEXNAME._WL', 'FUZZY_NUMRESULTS', '5000');
  ctx_ddl.set_attribute('&&INDEXNAME._WL', 'FUZZY_SCORE', '0');
  ctx_ddl.set_attribute('&&INDEXNAME._WL', 'STEMMER', 'GERMAN');
--  ctx_ddl.set_attribute('&&INDEXNAME._WL', 'SUBSTRING_INDEX', 'TRUE');
  ctx_ddl.set_attribute('&&INDEXNAME._WL', 'SUBSTRING_INDEX', 'FALSE');
  ctx_ddl.set_attribute('&&INDEXNAME._WL', 'WILDCARD_MAXTERMS', '2000');

  -- STORAGE PREFERENCE
  ctx_ddl.create_preference('&&INDEXNAME._ST', 'basic_storage');
  ------- PATTERN TABLE (substringindex - lefttruncated search)
  ctx_ddl.set_attribute('&&INDEXNAME._ST', 'p_table_clause',
         'tablespace &&TBSNAME nologging');
  ------- MATCH TABLE (rowid -> internal docid)
  ctx_ddl.set_attribute('&&INDEXNAME._ST', 'k_table_clause',
         'tablespace &&TBSNAME nologging');
  ------- MATCH TABLE (internal docid -> rowid)
  ctx_ddl.set_attribute('&&INDEXNAME._ST', 'r_table_clause',
         'tablespace &&TBSNAME nologging '||
         'lob(data) store as (tablespace &&TBSNAME cache)');
  ------- NEGATIV TABLE (deleted docids)
  ctx_ddl.set_attribute('&&INDEXNAME._ST', 'n_table_clause',
         'tablespace &&TBSNAME nologging');
  ------- TOKEN TABLE
  ctx_ddl.set_attribute('&&INDEXNAME._ST', 'i_table_clause',
         'tablespace &&TBSNAME nologging');
  ------- TOKEN TABLE INDEX
  ctx_ddl.set_attribute('&&INDEXNAME._ST', 'i_index_clause',
         'tablespace &&TBSNAME nologging compress 2');
  ------- SDATA TABLE (sdata column/section tokens)
  ctx_ddl.set_attribute('&&INDEXNAME._ST', 's_table_clause',
         'tablespace &&TBSNAME nologging');
end;
/
create index "&&INDEXNAME." on &&TABELLE.(&&SPALTE.) 
       indextype is ctxsys.context 
       FILTER BY POOL
       parameters('
       FILTER        CTXSYS.NULL_FILTER
       STOPLIST      CTXSYS.EMPTY_STOPLIST
       DATASTORE     &&INDEXNAME._DS
       SECTION GROUP &&INDEXNAME._SG
       STORAGE       &&INDEXNAME._ST 
       LEXER         &&INDEXNAME._LX 
       WORDLIST      &&INDEXNAME._WL 
       MEMORY        &&MEMORY.')
;
--
-- update trigger for actualisation of text index on column OTXML
--
create or replace
trigger mytrigger
before update on &&TABELLE
for each row
begin
  dbms_output.put_line('mytrigger fired');
  --if :neu.text != :old.text
  if 1=2
  then
    dbms_output.put_line('mytrigger update otxml');  
    :new.otxml := :new.otxml;
  end if;
  dbms_output.put_line('mytrigger ende');
end;
/
alter trigger mytrigger compile;

-- test case 1:
-- update on column pool should not result in pending row 
-- because of mdata column and trigger should not change :neu.otxml

select idx_name,idx_table,idx_docid_count from ctx_user_indexes where idx_table='&&TABELLE';
select * from &&TABELLE;
select * from ctx_user_pending;
update &&TABELLE set pool='X';
select * from ctx_user_pending;

-- as you can see .. update of mdata column forced a pending row 
-- this means text index on column OTXML was marked for resync
-- but updates on mdata columns doesn't marke the row for a resync !!!
-- the resync was marked by changing the OTXML column value in trigger code (:new.otxml := :new.otxml;)
-- but this must not happend because of IF condition (1=2) is false every time
-- end of test case 1!

pause please press enter ...

rollback;

-- test case 2:
-- update with uncommented :new.otxml change in trigger

create or replace
trigger mytrigger
before update on &&TABELLE
for each row
begin
  dbms_output.put_line('mytrigger fired');
  --if :neu.text != :old.text
  if 1=2
  then
    dbms_output.put_line('mytrigger update otxml');
    -- :new.otxml := :new.otxml;
  end if;
  dbms_output.put_line('mytrigger ende');
end;
/
alter trigger mytrigger compile;

select * from &&TABELLE;
select * from ctx_user_pending;
update &&TABELLE set pool='X';
select * from ctx_user_pending;

-- as you can see .. the update mdata column doesn't forced a pending row
-- the mdata column update doesn't mark the row for resync .. allright.
-- with uncommented line (:new.otxml := :new.otxml;) it works fine
-- but this line should not be evaluated because IF clause is not true.

-- is it a pl/sql bug?
-- if not .. how should i force text index to mark the row for resync
-- a) when an update on column TEXT runs 
-- b) but exclude updates on column POOL from this behavior?

pause please press enter ...

--
-- clean up all test data
--
begin
  ctx_ddl.drop_preference('&&INDEXNAME._LX');
  ctx_ddl.drop_preference('&&INDEXNAME._WL');
  ctx_ddl.drop_preference('&&INDEXNAME._ST');
  ctx_ddl.drop_preference('&&INDEXNAME._DS');
  ctx_ddl.drop_section_group('&&INDEXNAME._SG');
end;
/
drop table mytable;

--
undefine SPALTE
undefine TABELLE
undefine INDEXNAME
undefine TBSNAME
undefine MEMORY
undefine DATASTORE
--

