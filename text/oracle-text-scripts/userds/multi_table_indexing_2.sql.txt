
prompt  > Create a single Oracle Text index on the contents of multiple tables.
prompt  > This example uses a USER_DATASTORE to create virtual documents "on the fly" for indexing

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

drop table text_table_2;

create table text_table_2 (
   id      number, 
   tab_id  varchar2(30), 
   dummy   char(1) )
/

prompt  > Create the text table with one row per donor table
prompt  > We will just have a 'X' in the dummy column

insert into text_table_2 (
   select id, 'T1', 'X'
   from t1
);
insert into text_table_2 (
   select id, 'T2', 'X'
   from t2
);
insert into text_table_2 (
   select id, 'T3', 'X'
   from t3
);

prompt  > Now create a user datastore which will fetch all the relevant data for indexing

exec ctx_ddl.drop_preference(   'my_uds' )
exec ctx_ddl.create_preference( 'my_uds', 'user_datastore' )

exec ctx_ddl.set_attribute(     'my_uds', 'procedure', 'user_ds_procedure' )

prompt  > A simple policy is needed to process the binary documents in the user datastore
exec ctx_ddl.create_policy(     'my_pol', 'ctxsys.auto_filter' )

prompt  > Create the actual user datastore procedure

create or replace procedure user_ds_procedure (
    rid  in              rowid,
    tlob in out NOCOPY   clob ) is

  v_id      number;
  v_tab_id  varchar2(30);

  tmp_bfile  bfile;
  tmp_clob  clob;

begin
  -- We need to find out where this row comes from
  select id, tab_id 
  into v_id, v_tab_id
  from text_table_2
  where rowid = rid;

  case v_tab_id 

    when 'T1' then

       -- For T1 we use a simple join to fetch data from T2, using the ID we get from text_table_2
       select '<col_A>' || col_A || '</col_A><col_B>' || col_B || '</col_B>'
       into tlob
       from t1, text_table_2 tt
       where tt.rowid = rid
       and t1.id = tt.id;

    when 'T2' then

       -- For T2 we have a CLOB column. The same technique as T1 will work, but we 
       -- could also do all the clob reading manually using DBMS_LOB.READ
       -- might be more efficient but would be much more work
       select '<col_C>' || col_C || '</col_C><col_D>' || col_D || '</col_D>'
       into tlob
       from t2, text_table_2 tt
       where tt.rowid = rid
       and t2.id = tt.id;
       

    when 'T3' then

       -- For T3 there's a BFILE column - a binary column which needs filtering.
       -- We'll need to do extra work here
       select '<col_E>' || col_E || '</col_E><col_F>', col_F
       into tlob, tmp_bfile
       from t3, text_table_2 tt
       where tt.rowid = rid
       and t3.id = tt.id;

       -- Filter the binary data into a temp clob
       dbms_lob.createtemporary( tmp_clob, TRUE );
       ctx_doc.policy_filter( 'my_pol', tmp_bfile, tmp_clob );

       -- Concat that to the LOB to be returned and close the tag
 
       tlob := tlob || tmp_clob || '<col_F>';

  end case;

end;
/
list
show errors

prompt  > AUTO_SECTION_GROUP will automatically identify all sections created by user datastore (one per column)
prompt  > for better performance we could explicitly define field sections for each column
prompt  > In that case we could also define col_B as an SDATA section instead of using FILTER_BY in 
prompt  > the create index statement

exec ctx_ddl.drop_section_group(    'my_sg' )
exec ctx_ddl.create_section_group(  'my_sg', 'auto_section_group' )

-- Following not allowed with AUTO_SECTION_GROUP. Could use it with BASIC_ or HTML_SECTION_GROUP
-- exec ctx_ddl.add_sdata_section(  'my_sg', 'COL_A', 'COL_A', 'NUMBER' ); 

prompt  > Create the triggers which keep the main table updated. 
prompt  > We need an insert and update trigger for each table

prompt  > Insert Triggers
prompt  > these just insert the ID and tab identifier, and 'X' into the dummy column
prompt  > the user datastore will automatically pick up the actual data for indexing

create or replace trigger trig1i_uds
after insert 
  on t1
  for each row
begin
  insert into text_table_2 values
    ( :new.id, 'T1', 'X' );
end;
/
create or replace trigger trig2i_uds
after insert 
  on t2
  for each row
begin
  insert into text_table_2 values
    ( :new.id, 'T2', 'X' );
end;
/
create or replace trigger trig3i_uds
after insert 
  on t3
  for each row
begin
  insert into text_table_2 values
    ( :new.id, 'T3', 'X' );
end;
/

prompt  > Update Triggers:

--  WARNING: we assume "ID" never changes. If this is not the case, alter the trigger appropriately

create or replace trigger trig1u_uds
after update 
  on t1 
  for each row
begin
  if :new.col_A != :old.col_A then
     update text_table_2 tt set dummy = dummy
     where tt.id  = :new.id 
     and   tab_id = 'T1';
  end if;
  if :new.col_B != :old.col_B then
     update text_table_2 tt set dummy = dummy
     where tt.id  = :new.id 
     and   tab_id = 'T1';
  end if;
end;
/
create or replace trigger trig2u_uds
after update 
  on t2 
  for each row
begin
  if :new.col_C != :old.col_C then
     update text_table_2 tt set dummy = dummy
     where tt.id  = :new.id 
     and   tab_id = 'T2';
  end if;
  --  column D is a CLOB
  if dbms_lob.compare( :new.col_D, :old.col_D ) != 0 then 
     update text_table_2 tt set dummy = dummy
     where tt.id  = :new.id 
     and   tab_id = 'T2';
  end if;
end;
/
create or replace trigger trig3u_uds
after update 
  on t3 
  for each row
begin
  if :new.col_E != :old.col_E then
     update text_table_2 tt set dummy = dummy
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

create index text_index_2 on text_table_2( dummy )
indextype is ctxsys.context
parameters( 'datastore my_uds section group my_sg' )
/

prompt  > Check for any filtering or datastore errors

select * from ctx_user_index_errors;

prompt  > Try some queries

select id, tab_id from text_table_2 where contains ( dummy, 'john' ) >0;
select id, tab_id from text_table_2 where contains ( dummy, 'john within col_A' ) >0;
select id, tab_id from text_table_2 where contains ( dummy, 'document within col_F' ) >0;

prompt  > Add some new data

insert into t1 values ( 2, 'Andrew Smith', 3 );

prompt  > Sync the index

exec ctx_ddl.sync_index( 'text_index_2' );

prompt  > Search for the new data

select id, tab_id from text_table_2 where contains ( dummy, 'andrew' ) >0;

prompt  > Update the CLOB column in table T2

update t2 set col_d = 'fred johnson';

prompt  > Sync the index

exec ctx_ddl.sync_index( 'text_index_2' );

prompt  > Search for the new data

select id, tab_id from text_table_2 where contains ( dummy, 'johnson within col_d' ) >0;
