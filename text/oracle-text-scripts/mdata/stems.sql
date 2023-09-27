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
   hobby     varchar2(2000),
   text      clob);

-- Now the data.

insert into test_length values (1,
'cooking',
'the quick brown fox');

insert into test_length values (2,
'cookery',
'jumps over the lazy dog');

create table lookup_tab
 (longname    varchar2(4000),
  stem        varchar2(20));

insert into lookup_tab values 
('cookery', 'cook');

insert into lookup_tab values 
('cooking', 'cook');

-- we're going to use a User Datastore to create the indexable 'XML'
-- the user datastore is responsible for looking up the short word stem

create or replace procedure my_datastore_proc (the_rowid rowid, ret_clob in out nocopy clob)
is
  v_hobby varchar2(2000);
  v_stem  varchar2(20);
  v_text  varchar2(32767);
  v_buff  varchar2(32767);
begin
  select hobby, text into v_hobby, v_text
  from test_length
  where rowid = the_rowid;

  select stem into v_stem
    from lookup_tab 
    where longname = v_hobby;

  v_buff := '<hobby>' || v_stem || '</hobby>'
         || '<text>' || v_text || '</text>';
 
  dbms_lob.write (ret_clob, length(v_buff), 1, v_buff);

end my_datastore_proc;
/
show errors

-- Now create the index, creating the section group and user datastore preference
-- as needed

exec ctx_ddl.create_section_group(group_name=>'mysg', group_type=>'xml_section_group')
exec ctx_ddl.add_mdata_section(group_name=>'mysg', section_name=>'hobby', tag=>'hobby')

exec ctx_ddl.create_preference('myds', 'user_datastore')
exec ctx_ddl.set_attribute('myds', 'procedure', 'my_datastore_proc')

create index test_index on test_length (text)
indextype is ctxsys.context 
parameters ('datastore myds section group mysg');

select err_text from ctx_user_index_errors where err_index_name = 'TEST_INDEX';

-- Now we can't do queries unless the queries substitute the stem as well
-- so we'll create a short PL/SQL function to translate long cookery into short

create or replace function get_stem(p_longname varchar2) return varchar2 is
  v_stem varchar2(20);
begin
  select stem into v_stem
    from lookup_tab
    where longname = p_longname;
  return v_stem;
end get_stem;
/
show errors

-- Check the mdata in the index

column token_text format a30
select token_text, token_type, token_first, token_last, token_count
from dr$test_index$i
where token_type >= 400 or token_type <= -400;

-- then we use this function within our queries - substituting the short
-- stem into the MDATA part of the CONTAINS clause.
-- Both these queries should fetch both rows

select hobby from test_length
where contains (text,
'mdata(hobby,'|| get_stem('cookery') ||')') > 0;

select hobby from test_length
where contains (text,
'mdata(hobby,'|| get_stem('cooking') ||')') > 0;
