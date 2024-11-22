
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
  ctx_ddl.create_preference('&&INDEXNAME._DS','MULTI_COLUMN_DATASTORE');
  ctx_ddl.set_attribute('&&INDEXNAME._DS','COLUMNS','TEXT');
end;
/
create index "&&INDEXNAME." on &&TABELLE.(&&SPALTE.) 
       indextype is ctxsys.context 
       parameters('
       FILTER        CTXSYS.NULL_FILTER
       STOPLIST      CTXSYS.EMPTY_STOPLIST
');

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
-- the resync was marked by changing the OTXML column value in trigger code (:new.otxml := :new.otxml;)
-- but this must not happend because of IF condition (1=2) is false every time
-- end of test case 1!

pause please press enter ...

--
-- clean up all test data
--
begin
  ctx_ddl.drop_preference('&&INDEXNAME._DS');
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

