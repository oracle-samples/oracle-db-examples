set echo on

drop index lib_index;
drop table library_stock;
exec ctx_ddl.drop_section_group('mysg');
exec ctx_ddl.drop_preference('myds');

create table library_stock 
  (id         number primary key, 
   title      varchar2(2000),
   author     varchar2(2000),
   stocklevel number);

insert into library_stock values (1, 'A Prayer for Owen Meany', 'John Irving', 1);
insert into library_stock values (2, 'The World According to Garp', 'John Irving', 12);
insert into library_stock values (3, 'The Hotel New Hampshire', 'John Irving', 0);

create or replace procedure my_datastore_proc (the_rowid rowid, ret_clob in out nocopy clob)
is
  v_title      varchar2(2000);
  v_author     varchar2(2000);
  v_status     varchar2(20);
  v_stocklevel number;
  v_buff       varchar2(32767);
begin
  select title,   author,   stocklevel
    into v_title, v_author, v_stocklevel
  from library_stock
  where rowid = the_rowid;

  if v_stocklevel > 0 then
     v_status := 'In Stock';
  else
     v_status := 'Out of Stock';
  end if;

  v_buff := '<title>'     ||v_title     ||'</title>'
         || '<author>'    ||v_author    ||'</author>'
         || '<status>'    ||v_status    ||'</status>'
         || '<stocklevel>'||v_stocklevel||'</stocklevel>';

  dbms_lob.write (ret_clob, length(v_buff), 1, v_buff);

end my_datastore_proc;
/
show errors

-- We need a trigger to keep updates in sync.
-- Remember TITLE is the indexed column. So if
--   TITLE changes - index is updated automatically
--   AUTHOR changes - we need to force a re-index by modifying TITLE
--   STOCKLEVEL changes, we should just update the metadata

-- First trigger will deal only with changes to AUTHOR
create or replace trigger lib_author_trigger 
before update of author on library_stock
for each row
begin
  :new.title := :new.title;
end lib_author_trigger;
/
show errors

-- Second trigger will deal with STOCKLEVEL changes
-- for this to work you must EXPLICITLY run the following
-- as a DBA user, or CTXSYS
-- "grant execute on ctx_ddl to <username>"

create or replace trigger lib_stocklevel_trigger
before update of stocklevel on library_stock
for each row
declare 
  v_newstatus varchar2(20);
  v_oldstatus varchar2(20);
begin
  ctx_ddl.remove_mdata(
      idx_name     => 'lib_index', 
      section_name => 'stocklevel', 
      mdata_value  => :old.stocklevel, 
      mdata_rowid  => :new.rowid);
  ctx_ddl.add_mdata(  
      idx_name     => 'lib_index', 
      section_name => 'stocklevel', 
      mdata_value  => :new.stocklevel, 
      mdata_rowid  => :new.rowid);

  if :new.stocklevel = 0 or :old.stocklevel = 0 then
      if :new.stocklevel = 0 then
         v_newstatus := 'Out of Stock';
         v_oldstatus := 'In Stock';
      else
         v_newstatus := 'In Stock';
         v_oldstatus := 'Out of Stock';
      end if;

      ctx_ddl.remove_mdata(
        idx_name     => 'lib_index', 
        section_name => 'status', 
        mdata_value  => v_oldstatus, 
        mdata_rowid  => :new.rowid);
      ctx_ddl.add_mdata(  
        idx_name     => 'lib_index', 
        section_name => 'stocklevel', 
        mdata_value  => v_newstatus, 
        mdata_rowid  => :new.rowid);
  end if;
end lib_stocklevel_trigger;
/

exec ctx_ddl.create_preference('myds', 'user_datastore')
exec ctx_ddl.set_attribute    ('myds', 'procedure', 'my_datastore_proc')

exec ctx_ddl.create_section_group(group_name=>'mysg', group_type=>'xml_section_group');

exec ctx_ddl.add_field_section(group_name=>'mysg', section_name=>'title', tag=>'title', visible=>TRUE);
exec ctx_ddl.add_field_section(group_name=>'mysg', section_name=>'author', tag=>'author', visible=>TRUE);

exec ctx_ddl.add_mdata_section(group_name=>'mysg', section_name=>'status', tag=>'status');
exec ctx_ddl.add_mdata_section(group_name=>'mysg', section_name=>'stocklevel', tag=>'stocklevel');

create index lib_index on library_stock (title)
indextype is ctxsys.context 
parameters ('datastore myds section group mysg');

select err_text from ctx_user_index_errors where err_index_name = 'LIB_INDEX';

set long 10000

column title format a40

select id, title, stocklevel from library_stock 
where contains (title, 
'irving within author and mdata(status, In Stock)') > 0;

update library_stock set author = 'John Smith' where id = 2;

exec ctx_ddl.sync_index ('lib_index')

select id, title, stocklevel from library_stock 
where contains (title, 
'irving within author and mdata(status, In Stock)') > 0;

update library_stock set stocklevel = stocklevel - 1
where id = 1;

select id, title, stocklevel from library_stock 
where contains (title, 
'irving within author and mdata(status, In Stock)') > 0;

select id, title, stocklevel from library_stock 
where contains (title, 
'irving within author and mdata(status, Out of Stock)') > 0;
