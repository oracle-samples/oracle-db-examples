set echo on

-- drop everything we're going to use - expect errors here first time
drop index test_index;
drop table lookup_tab;
drop table test_length;
exec ctx_ddl.drop_section_group('mysg')
exec ctx_ddl.drop_preference('myds')


-- here's our table

create table test_length 
  (id number primary key, 
   code      varchar2(2000),
   text      clob);

-- we're going to use a User Datastore to create the indexable 'XML'
-- the user datastore concatenates the fields within suitable tags

create or replace procedure my_datastore_proc (the_rowid rowid, ret_clob in out nocopy clob)
is
  v_code  varchar2(2000);
  v_text  varchar2(32767);
  v_buff  varchar2(32767);
begin
  select code, text into v_code, v_text
  from test_length
  where rowid = the_rowid;

  v_buff := '<code>' || v_code || '</code>'
         || '<text>' || v_text || '</text>';

  dbms_lob.write (ret_clob, length(v_buff), 1, v_buff);

end my_datastore_proc;
/
show errors

-- Now the data. The 'code' values vary only in the last (71st) characters

insert into test_length values (1,
'a123456789b1234567889c123456789d123456789e123456789f123456789g123456789x',
'the quick brown fox');

insert into test_length values (2,
'a123456789b1234567889c123456789d123456789e123456789f123456789g123456789y',
'jumps over the lazy dog');

-- Now create the index, creating the section group and user datastore preference
-- as needed

exec ctx_ddl.create_section_group(group_name=>'mysg', group_type=>'xml_section_group')
exec ctx_ddl.add_mdata_section(group_name=>'mysg', section_name=>'code', tag=>'code')

exec ctx_ddl.create_preference('myds', 'user_datastore')
exec ctx_ddl.set_attribute('myds', 'procedure', 'my_datastore_proc')

create index test_index on test_length (text)
indextype is ctxsys.context 
parameters ('datastore myds section group mysg');

select err_text from ctx_user_index_errors where err_index_name = 'TEST_INDEX';

-- Examine the token table for MDATA tokens. Note that there is only one
--  - it's the two CODE values truncated to 64 characters and therefore the same

column token_text format a30
select token_text, token_type, token_first, token_last
from dr$test_index$i
where token_type >= 400 or token_type <= -400;

-- Now we should find that a query for one of the CODE values in MDATA 
-- finds both of them:

select code from test_length
where contains (text,
'mdata(code, 
a123456789b1234567889c123456789d123456789e123456789f123456789g123456789x)'
) > 0;

-- So here's the workaround. We create a lookup table, containing the long
-- code values and a short lookup code.  (The index on the lookup table is
-- fairly pointless here but would be important if there were many rows).

create table lookup_tab
 (shortcode    number,
  value        varchar2(4000));

insert into lookup_tab values 
  (1, 'a123456789b1234567889c123456789d123456789e123456789f123456789g123456789x');

insert into lookup_tab values 
  (2, 'a123456789b1234567889c123456789d123456789e123456789f123456789g123456789y');

create index lookup_ind on lookup_tab (value);

-- Now we re-create the User Datastore procedure, but this time we'll lookup
-- the relevant short code from the lookup table, and insert that into the
-- <code> section instead of the full value

create or replace procedure my_datastore_proc (the_rowid rowid, ret_clob in out nocopy clob)
is
  v_code      varchar2(2000);
  v_text      varchar2(32767);
  v_buff      varchar2(32767);
  v_shortcode varchar2(10);
begin
  select code, text into v_code, v_text
  from test_length
  where rowid = the_rowid;

  select shortcode into v_shortcode
  from lookup_tab 
  where value = v_code;

  v_buff := '<code>' || v_shortcode || '</code>'
         || '<text>' || v_text || '</text>';

  dbms_lob.write (ret_clob, length(v_buff), 1, v_buff);

end my_datastore_proc;
/
show errors

-- recreate the index. Don't need to recreate preference or section group
-- as they are the same as before

drop index test_index;

create index test_index on test_length (text)
indextype is ctxsys.context 
parameters ('datastore myds section group mysg');

select err_text from ctx_user_index_errors where err_index_name = 'TEST_INDEX';

-- Check the token table - should now see two MDATA tokens

column token_text format a30
select token_text, token_type, token_first, token_last
from dr$test_index$i
where token_type >= 400 or token_type <= -400;

-- Now we can't do queries unless the queries substitute the short code as well
-- so we'll create a short PL/SQL function to translate long code into short

create or replace function get_shortcode(code varchar2) return varchar2 is
  v_shortcode varchar2(10);
begin
  select shortcode into v_shortcode 
  from lookup_tab
  where value = code;
  return v_shortcode;
end get_shortcode;
/
show errors

-- then we use this function within our queries - substituting the short
-- code into the MDATA part of the CONTAINS clause.
-- This time we should only fetch a single row

select code from test_length
where contains (text,
'mdata(code,'|| get_shortcode(
'a123456789b1234567889c123456789d123456789e123456789f123456789g123456789x')
||')') > 0;
