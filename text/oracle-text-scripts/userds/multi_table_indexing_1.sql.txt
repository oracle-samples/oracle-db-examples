
prompt  > Create a single Oracle Text index on the contents of multiple tables.
prompt  > This exampel uses the technique of copying all the data into a central table for indexing
prompt  > using the multi column datastore

prompt  > user running this example must have CTX_APP role and CREATE ANY DIRECTORY priv

prompt  > We have 3 tables:
prompt  >   T1 has one VARCHAR2 and one numeric columns
prompt  >   T2 has one VARCHAR2 column and one CLOB
prompt  >   T2 has one VARCHAR2 column and one BFILE

drop table t1;
drop table t2;
drop table t3;

create table t1( id number primary key, col_A varchar2(2000), col_B number );
create table t2( id number primary key, col_C varchar2(2000), col_D clob );
create table t3( id number primary key, col_E varchar2(2000), col_F bfile );

prompt  > need a directory only for BFILENAME. Make sure this directory exists and contains 
prompt  > an MSWord file called "1.doc", preferably containing just the string "test document"

create or replace directory FILE_DIR as 'C:\doc';

insert into t1 values ( 1, 'john smith', 99 );
insert into t2 values ( 1, 'fred bloggs', 'clob text' );
insert into t3 values ( 1, 'john doe', bfilename( 'FILE_DIR', '1.doc' ) );

drop table text_table;

create table text_table (
   id      number, 
   tab_id  varchar2(30), 
   col_A   varchar2(2000),
   col_B   number,
   col_C   varchar2(2000),
   col_D   clob,
   col_E   varchar2(2000),
   col_F   bfile )
/

prompt  > Do the data copy

insert into text_table (
   select id, 'T1', col_A, col_B, null,  null,  null,  null
   from t1
);
insert into text_table (
   select id, 'T2', null,  null,  col_C, col_D, null,  null 
   from t2
);
insert into text_table (
   select id, 'T3', null,  null,  null,  null,  col_E, col_F
   from t3
);

prompt  > Now create a multi_column_datastore which references all columns

exec ctx_ddl.drop_preference(   'my_mcds' )
exec ctx_ddl.create_preference( 'my_mcds', 'multi_column_datastore' )

exec ctx_ddl.set_attribute(     'my_mcds', 'columns', 'col_A, col_B, col_C, col_D, col_E, col_F' )
exec ctx_ddl.set_attribute(     'my_mcds', 'filter',  'N,     N,     N,     N,     N,     Y' )

prompt  > AUTO_SECTION_GROUP will automatically identify all sections created by mcds (one per column)
prompt  > for better performance we could explicitly define field sections for each column
prompt  > In that case we could also define col_B as an SDATA section instead of using FILTER_BY in 
prompt  > the create index statement

exec ctx_ddl.drop_section_group(    'my_sg' )
exec ctx_ddl.create_section_group(  'my_sg', 'auto_section_group' )

-- Following not allowed with AUTO_SECTION_GROUP. Could use it with BASIC_ or HTML_SECTION_GROUP
-- exec ctx_ddl.add_sdata_section(  'my_sg', 'COL_A', 'COL_A', 'NUMBER' ); 

prompt  > Create the triggers which keep the main table updated. 
prompt  > We need an insert and update trigger for each table

prompt  > Insert Triggers:

create or replace trigger trig1i
after insert 
  on t1
  for each row
begin
  insert into text_table values
    ( :new.id, 'T1', :new.col_A, :new.col_B, null, null, null, null );
end;
/
create or replace trigger trig2i
after insert 
  on t2
  for each row
begin
  insert into text_table values
    ( :new.id, 'T1', null, null, :new.col_C, :new.col_D, null, null );
end;
/
create or replace trigger trig3i
after insert 
  on t3
  for each row
begin
  insert into text_table values
    ( :new.id, 'T1', null, null, null, null, :new.col_E, :new.col_F  );
end;
/

prompt  > Update Triggers:
prompt  > 
prompt  > Our index is going to be on col_A, we need to update that column as well as
prompt  > any that actually change, otherwise the index update won't get invoked
prompt  > (We don't need to do this with insert triggers - text indexing is always invoked on an insert)
prompt  >
prompt  >  WARNING: we assume "ID" never changes. If this is not the case, alter the trigger appropriately

create or replace trigger trig1u
after update 
  on t1 
  for each row
begin
  if :new.col_A != :old.col_A then
     update text_table tt set col_A = :new.col_A
     where tt.id  = :new.id 
     and   tab_id = 'T1';
  end if;
  if :new.col_B != :old.col_B then
     update text_table tt set col_B = :new.col_B,
                              col_A = col_A
     where tt.id  = :new.id 
     and   tab_id = 'T1';
  end if;
end;
/
create or replace trigger trig2u
after update 
  on t2 
  for each row
begin
  if :new.col_C != :old.col_C then
     update text_table tt set col_C = :new.col_C,
                              col_A = col_A
     where tt.id  = :new.id 
     and   tab_id = 'T2';
  end if;
  --  column D is a CLOB
  if dbms_lob.compare( :new.col_D, :old.col_D ) != 0 then 
     update text_table tt set col_D = :new.col_D,
                              col_A = col_A
     where tt.id  = :new.id 
     and   tab_id = 'T2';
  end if;
end;
/
create or replace trigger trig3u
after update 
  on t3 
  for each row
begin
  if :new.col_E != :old.col_E then
     update text_table tt set col_E = :new.col_E,
                              col_A = col_A
     where tt.id  = :new.id 
     and   tab_id = 'T3';
  end if;
  -- column F is a BFILE
  -- We can't tell when the file has been updated. We can fire the trigger
  -- if the the BFILE pointer has changed, but not the contents of the file
  -- other mechanisms will need to used in this case.
end;
/

prompt  > Now we can create the index (at last)
prompt  > It makes no difference which column we create the index on,
prompt  > we could have included a "dummy" column for this purpose if we wanted

prompt  > drop index text_index (don't need this if we've dropped the table)

create index text_index on text_table( col_A )
indextype is ctxsys.context
filter by col_B
parameters( 'datastore my_mcds section group my_sg' )
/

prompt  > Check for any filtering errors

select * from ctx_user_index_errors;

prompt  > Try some queries

select id, tab_id from text_table where contains ( col_A, 'john' ) >0;
select id, tab_id from text_table where contains ( col_A, 'john within col_A' ) >0;
select id, tab_id from text_table where contains ( col_A, '(clob text) within col_D' ) >0;
select id, tab_id from text_table where contains ( col_A, 'document within col_F' ) >0;

prompt  > Add some new data

insert into t1 values ( 2, 'Andrew Smith', 3 );

prompt  > Sync the index

exec ctx_ddl.sync_index( 'text_index' );

prompt  > Search for the new data

select id, tab_id from text_table where contains ( col_A, 'andrew' ) >0;

prompt  > Update the CLOB column in table T2

update t2 set col_d = 'fred johnson';

prompt  > Sync the index

exec ctx_ddl.sync_index( 'text_index' );

prompt  > Search for the new data

select id, tab_id from text_table where contains ( col_A, 'johnson within col_d' ) >0;

