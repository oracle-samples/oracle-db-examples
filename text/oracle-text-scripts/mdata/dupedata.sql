set echo on

-- drop everything we're going to use - expect errors here first time
drop index test_index;
drop table lookup_tab;
drop table test_table;
exec ctx_ddl.drop_section_group('mysg')
exec ctx_ddl.drop_preference('myds')


-- here's our table

create table test_table 
  (id number primary key, 
   auth      varchar2(2000),
   text      clob);

-- we're going to use a User Datastore to create the indexable 'XML'
-- the user datastore concatenates the fields within suitable tags

create or replace procedure my_datastore_proc (the_rowid rowid, ret_clob in out nocopy clob)
is
  v_auth  varchar2(2000);
  v_text  varchar2(32767);
  v_buff  varchar2(32767);
begin
  select auth, text into v_auth, v_text
  from test_table
  where rowid = the_rowid;

  v_buff := '<auth>'   || v_auth || '</auth>'
         || '<ftauth>' || v_auth || '</auth>'
         || '<text>'   || v_text || '</text>';

  dbms_lob.write (ret_clob, length(v_buff), 1, v_buff);

end my_datastore_proc;
/
show errors

-- Now the data

insert into test_table values (1, 'William Shakespeare', 'Macbeth ... blah');
insert into test_table values (2, 'William Wordsworth', 'The Longest Day ... blah');

-- Now create the index, creating the section group and user datastore preference
-- as needed

exec ctx_ddl.create_section_group(group_name=>'mysg', group_type=>'xml_section_group')
exec ctx_ddl.add_mdata_section   (group_name=>'mysg', section_name=>'auth', tag=>'auth')
exec ctx_ddl.add_field_section   (group_name=>'mysg', section_name=>'ftauth', tag=>'ftauth', visible=>TRUE)

exec ctx_ddl.create_preference ('myds', 'user_datastore')
exec ctx_ddl.set_attribute     ('myds', 'procedure', 'my_datastore_proc')

create index test_index on test_table (text)
indextype is ctxsys.context 
parameters ('datastore myds section group mysg');

select err_text from ctx_user_index_errors where err_index_name = 'TEST_INDEX';

-- Examine the token table for MDATA tokens. 

column token_text format a30
select token_text, token_type, token_first, token_last
from dr$test_index$i
where token_type >= 400 or token_type <= -400;

-- Now we should find that a query for one of the AUTH values in MDATA 
-- finds both of them:

column auth format a30 
column text format a30

select auth, text from test_table
where contains (text, 'mdata(auth, William Wordsworth)') > 0;

select auth, text from test_table
where contains (text, 'william') > 0;

