-- Concatenated Datastore

-- Procedures to automatically create a user datastore that
-- concatenates multiple columns into a single column index.

-- TO DO :
-- Proper dynamic code
-- Procedure name derived from sequence, therefore dstore_name
--   need not be unique across users

connect ctxsys/ctxsys

--drop user roger cascade;
--create user roger identified by roger;
--grant connect,resource,ctxapp to roger;

drop table ctx_cdstores;

create table ctx_cdstores (
  cdstore_id   number(10) primary key,
  cdstore_name varchar2(23),
  owner        varchar2(30),
  table_name   varchar2(30)
);

drop table ctx_cdstore_cols;

create table ctx_cdstore_cols (
  cdstore_id   number(10),
  col_name     varchar2(30),
  section_name varchar2(30),
  visible      char(1),
  col_type     varchar2(4),
  min_val      number(8,0),
  max_val      number(8,0)
  );

create or replace view ctx_user_cdstores as
  select cdstore_id, cdstore_name, table_name
    from ctx_cdstores
    where owner = user;

grant select on ctx_user_cdstores
  to ctxapp;

drop public synonym ctx_user_cdstores;
create public synonym ctx_user_cdstores 
  for ctxsys.ctx_user_cdstores;

create or replace view ctx_user_cdstore_cols as
  select a.cdstore_id, a.cdstore_name, 
         b.col_name, b.section_name, b.visible, 
         b.col_type, b.min_val, b.max_val
    from ctx_cdstores a, ctx_cdstore_cols b
    where owner = user
    and a.cdstore_id = b.cdstore_id;

grant select on ctx_user_cdstore_cols
  to ctxapp;

drop public synonym ctx_user_cdstore_cols;
create public synonym ctx_user_cdstore_cols 
  for ctxsys.ctx_user_cdstore_cols;

drop sequence ctx_cdstore_seq;
create sequence ctx_cdstore_seq;

create or replace package ctx_cd is

  procedure new_cdstore(
     cdstore_name varchar2,
     table_name   varchar2);

  procedure add_column(
     cdstore_name varchar2,
     col_name     varchar2,
     section_name varchar2 default null,
     visible      boolean  default true,
     col_type     varchar2 default 'CHAR',
     min_val      integer  default null,
     max_val      integer  default null);

  procedure create_cdstore(
     cdstore_name  varchar2);

  procedure drop_cdstore(
     cdstore_name  varchar2);
end;
/
--list
show errors

create or replace package body ctx_cd is
  procedure new_cdstore(
     cdstore_name varchar2,
     table_name   varchar2) is
    cnt number;
    l_cdstore varchar2(30);
    l_table_name varchar2(30);
  begin
    -- copy args to local vars to avoid confusion with column names
    l_cdstore    := upper(cdstore_name);
    l_table_name := upper(table_name);

    -- Check it doesn't already exist
    select count(*) into cnt from ctx_cdstores
    where cdstore_name = l_cdstore;

    if (cnt > 0) then
      raise_application_error 
        (-20000, 'name already in use for concatenated datastore');
    end if;

    -- Get a reference number for this concat dstore
    select ctx_cdstore_seq.nextval
    into cnt
    from dual;
    
    insert into ctx_cdstores (
      cdstore_id, cdstore_name, owner, table_name)
      values (
      cnt, l_cdstore, user, l_table_name);

  end new_cdstore;

  procedure add_column(
     cdstore_name  varchar2,
     col_name     varchar2,
     section_name varchar2 default null,
     visible      boolean  default true,
     col_type     varchar2 default 'CHAR',
     min_val      integer default null,
     max_val      integer default null) is
    id number;
    l_name varchar2(30);
    l_col_name     varchar2(30);
    l_sec_name     varchar2(30);
    l_visible      char(1);
    l_col_type     varchar2(30);
    l_min_val      integer;
    l_max_val      integer;
  begin
    -- copy args to local vars to avoid confusion with col names
    l_name     := upper(cdstore_name);
    l_col_name := upper(col_name);
    l_col_type := upper(col_type);
    l_min_val  := min_val;
    l_max_val  := max_val;
    if (visible) then 
      l_visible  := 'Y';
    else
      l_visible  := 'N';
    end if;

    -- If section name is null, set it to the column name.
    -- If empty string, then section will have no tags

    if (section_name is null) then
      l_sec_name := l_col_name;
    else 
      l_sec_name := upper(section_name);
    end if;

    -- Validate that cdstore exists

    begin
      select cdstore_id into id
      from ctx_cdstores
      where owner = user
      and cdstore_name = l_name;

    exception
      when no_data_found
      then
        raise_application_error
           (-20000, 'concatenated datastore does not exist');
    end;

    -- Validated that cdstore exists OK
    -- now store col data

    insert into ctx_cdstore_cols (
      cdstore_id, col_name, section_name, visible, col_type, min_val, max_val)
     values (
      id, l_col_name, l_sec_name, l_visible, l_col_type, l_min_val, l_max_val);
   
  end;

  procedure create_cdstore(
     cdstore_name  varchar2) is
    the_name varchar2(30) default 'testprocedure';
    proc_buffer     varchar2(32767);
    cnt             integer;
    l_cdstore_name  varchar2(30);
    l_user          varchar2(30);
    tab             varchar2(30);
  begin

   l_cdstore_name := upper(cdstore_name);

   -- First check that the table does exist. Otherwise we
   -- will get errors when trying to compile the dynamic
   -- proc that references it

   -- get username (used later)
   select user into l_user
   from dual;

   -- get table name
   begin
     select table_name into tab
       from ctx_user_cdstores
       where cdstore_name = l_cdstore_name;
   exception
     when no_data_found then
       raise_application_error (-20000,
         'concatenated datastore '||l_cdstore_name||' does not exist');
   end;

   -- check data dictionary
   select count(*) into cnt
   from all_tables
   where owner = user
   and table_name = tab;

   if (cnt = 0) then
     raise_application_error (-20000,
        'table '||tab||' does not exist');
   end if;

   -- table verified. Create the dynamic procedure

   execute immediate 
    'create or replace procedure ' || the_name          || chr(10) || 
    '  ( t in varchar2 )'                               || chr(10) || 
    'is'                                                || chr(10) || 
    'begin'                                             || chr(10) || 
    '  Dbms_Output.Put_Line ( t || t );'                || chr(10) || 
    'end;';

  -- Create the section group
  -- This is just to prove it can be done. Needs to be
  -- dynamic - name same as cdstore_name ?

  begin
    execute immediate (
      'begin ctx_ddl.drop_section_group '        ||
        '(group_name  => ''my_cdstore'') ; end ; ');
  exception
    when others then
      null;
  end;

  execute immediate (
    'begin ctx_ddl.create_section_group ('     ||
      'group_name   => ''my_cdstore'', ' ||
      'group_type   => ''basic_section_group'') ; end ; ');

  execute immediate (
    'begin ctx_ddl.add_field_section ('        ||
      'group_name   => ''my_cdstore'','  ||
      'section_name => ''title'','       ||
      'tag          => ''title'','       ||
      'visible      => true ) ; end ; ');

  -- Create the datastore procedure
  proc_buffer :=
'create or replace procedure my_cdstore'   || chr(10) ||
' (rid in rowid,'   || chr(10) ||
'  tlob in out nocopy clob ) is'   || chr(10) ||
' tag1 varchar2(2000) := ''title'';'   || chr(10) ||
' tag2 varchar2(2000) := ''author'';'   || chr(10) ||
' tag3 varchar2(2000) := ''abstract'';'   || chr(10) ||
' vvc1 varchar2(32767);'   || chr(10) ||
' vvc2 varchar2(32767);'   || chr(10) ||
' vclob clob;'   || chr(10) ||
' v_buffer                       varchar2(4000);'   || chr(10) ||
' v_length                       integer;'   || chr(10) ||
'begin'   || chr(10) ||
'select title, author, abstract'   || chr(10) ||
'    into vvc1, vvc2, vclob'   || chr(10) ||
'    from roger.concat_table where rowid = rid;'   || chr(10) ||
''   || chr(10) ||
'  v_buffer := '   || chr(10) ||
'              ''<''  || tag1 || ''>'' ||'   || chr(10) ||
'              vvc1 ||'   || chr(10) ||
'              ''</'' || tag1 || ''>'' ||'   || chr(10) ||
'              ''<''  || tag2 || ''>'' ||'   || chr(10) ||
'              vvc2 ||'   || chr(10) ||
'              ''</'' || tag2 || ''>'' ||'   || chr(10) ||
'              ''< '' || tag3 || ''>'';'   || chr(10) ||
''   || chr(10) ||
'  v_length := length ( v_buffer );'   || chr(10) ||
''   || chr(10) ||
'  Dbms_Lob.Trim'   || chr(10) ||
'    ('   || chr(10) ||
'      lob_loc        => tlob,'   || chr(10) ||
'      newlen         => 0'   || chr(10) ||
'    );'   || chr(10) ||
''   || chr(10) ||
'  Dbms_Lob.Write'   || chr(10) ||
'    ('   || chr(10) ||
'      lob_loc        => tlob,'   || chr(10) ||
'      amount         => v_length,'   || chr(10) ||
'      offset         => 1,'   || chr(10) ||
'      buffer         => v_buffer'   || chr(10) ||
'    );'   || chr(10) ||
''   || chr(10) ||
'  Dbms_Lob.Copy'   || chr(10) ||
'    ('   || chr(10) ||
'      dest_lob      => tlob,'   || chr(10) ||
'      src_lob       => vclob,'   || chr(10) ||
'      amount        => Dbms_Lob.GetLength ( vclob ),'   || chr(10) ||
'      dest_offset   => v_length + 1,'   || chr(10) ||
'      src_offset    => 1'   || chr(10) ||
'    );'   || chr(10) ||
''   || chr(10) ||
'  Dbms_Lob.WriteAppend'   || chr(10) ||
'    ('   || chr(10) ||
'      lob_loc  => tlob,'   || chr(10) ||
'      amount   => length ( ''</'' || tag3 || ''>'' ),'   || chr(10) ||
'      buffer   => ''</'' || tag3 || ''>'''   || chr(10) ||
'    );'   || chr(10) ||
'end;'   || chr(10);

  execute immediate proc_buffer;
  
  execute immediate 
       ('grant execute on ' || l_cdstore_name || ' to ' || l_user);

  -- Create the datastore (delete first but ignore "does not exist" err)
  begin
    execute immediate
       ('begin ctx_ddl.drop_preference(''my_cdstore'') ; end ;');
  exception
    when others then
      null;
  end;

  execute immediate
     ('begin '                                                 ||
        'ctx_ddl.create_preference '                           || 
        '( ''' || l_cdstore_name || ''', ''user_datastore'' ); '   ||
        'ctx_ddl.set_attribute '                               || 
        '( ''' || l_cdstore_name || ''', ''procedure'',''' || l_cdstore_name ||''' ); ' ||
      'end;');
  end;


  procedure drop_cdstore(
     cdstore_name varchar2) is
    id              number;
    l_name          varchar2(30);
    no_such_object  exception;
    pragma exception_init(no_such_object, -4043);
  begin
    begin
      l_name := cdstore_name;
      select cdstore_id into id
      from ctx_cdstores
      where owner = user
      and cdstore_name = l_name;

      delete from ctx_cdstores
      where cdstore_id = id;

    exception
      when no_data_found
      then
        raise_application_error
           (-20000, 'concatenated datastore '||l_name||' does not exist');
    end;

    -- No data found is acceptable for this part

    delete from ctx_cdstore_cols
    where cdstore_id = id;

    -- drop the preference if it exists
    begin
      execute immediate
         ('begin ctx_ddl.drop_preference(''my_cdstore'') ; end ;');
    exception
      when others then
        null;
    end;

    -- drop the procedure
    begin
      execute immediate
        ('drop procedure '||l_dstore_name);
    exception
      when no_such_object then
        null;
    end;

  exception
    when no_data_found then
      null;
  end;

end;
/
list
show errors

grant execute on ctx_cd to ctxapp;
drop public synonym ctx_cd;
create public synonym ctx_cd for ctxsys.ctx_cd;

---------------------
---  USER PART ------
---------------------

connect roger/roger

set echo on
set serverout on

begin
  ctx_cd.new_cdstore    (
    cdstore_name => 'my_cdstore', 
    table_name   => 'concat_table');
end;
/

begin
  ctx_cd.add_column     (
    cdstore_name => 'my_cdstore', 
    col_name     => 'author');
end;
/
exec ctx_cd.add_column     ('my_cdstore', 'title')
exec ctx_cd.add_column     ('my_cdstore', 'abstract')

drop table concat_table;
create table concat_table (
  pk number primary key,
  title varchar2(2000),
  author varchar2(2000),
  concat varchar2(1),
  abstract clob
);

exec ctx_cd.create_cdstore (cdstore_name => 'my_cdstore')

column cdstore_name format a20
column col_name format a20
column section_name format a20

select * from ctx_user_cdstores;
select * from ctx_user_cdstore_cols;

insert into concat_table (pk, title, author, abstract) values 
 (1, 'Cartesian Dualism', 'Rene Descartes', 
 'discusses the plurality of mind and brain, and the '||
 'distinction between the extended and the unextended');
insert into concat_table (pk, title, author, abstract) values 
 (2, 'On the Electrodynamics of Moving Bodies', 'Albert Einstein',
 'Einstein''s classic paper on special relativity');
insert into concat_table (pk, title, author, abstract, concat) values 
 (3, 'Beer and Me', 'Homer Simpson',
 'Explores the unique relationship between a man and his beverage','a');

commit;

create index myindex on concat_table (abstract) indextype is ctxsys.context
  parameters ('datastore my_cdstore section group my_cdstore');

select abstract from concat_table where contains (abstract, 'beer within title')>0;

set echo off

--create or replace trigger ctx_cdstore_trg
-- before insert
-- on ctx_cdstore
-- for each row
--begin
-- select ctx_cdstore_seq.nextval into :new.cdstore_id from dual;
-- :new.owner := user;
--end;
--/
--


