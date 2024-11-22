-- Concatenated Datastore

-- Procedures to automatically create a user datastore that
-- concatenates multiple columns into a single column index.

-- TO DO :
-- order columns are returned - does this matter?
-- automatically derive col types for CHAR and CLOB
-- Procedure name should be derived from sequence, therefore dstore_name
--   need not be unique across users

connect ctxsys/ctxsys

exec dbms_output.enable(65000)
set serverout on

drop user roger cascade;
create user roger identified by roger;
grant connect,resource,ctxapp to roger;

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

  procedure drop_cdstore(
     cdstore_name  varchar2);

end;
/
--list
show errors

create or replace package body ctx_cd is

  function identifier_is_valid (the_name in varchar2)
    return boolean is
  p integer;
  disallowed varchar2(80) := ' !"%^&*()+={}[]@~''#?/<>,.|\`';
  c varchar2(1);

  begin
    for p in 1 .. length(the_name) loop
      c := substr(the_name, p, 1);
      if (instr (disallowed, c) > 0) then
         return false;
      end if;
    end loop;
    return true;
  end;

  procedure do_dynamic_setup (
     cdname varchar2, username varchar2, tablename varchar2) is
    proc_buffer varchar2(32767);

    type vch_tab is table of varchar2(30) index by binary_integer;
    type int_tab is table of integer index by binary_integer;

    col_names      vch_tab;
    sec_names      vch_tab;
    types          vch_tab;
    visibles       vch_tab;
    mins           int_tab;
    maxs           int_tab;

    cntr           integer := 0;
    char_cnt       integer := 0;
    clob_cnt       integer := 0;
    int_cnt        integer := 0;
    col_cnt        integer := 0;

    cursor cols (cname varchar2) is 
      SELECT   col_name, section_name, visible, col_type, min_val, max_val
      FROM     ctx_user_cdstore_cols
      WHERE    cdstore_name = cname
      ORDER BY col_type;
   
    select_clause  varchar2(2000);
    into_clause    varchar2(2000);
    comma          varchar2(2);

    v_col_name     varchar2(30);
    v_section_name varchar2(30);
    v_visible      varchar2(1);
    v_col_type     varchar2(4);
    v_min_val      integer;
    v_max_val      integer; 

  begin 

    open cols (cdname);
    cntr := 1;
    loop
      fetch cols into 
          col_names(cntr), sec_names(cntr), visibles(cntr), types(cntr),
          mins(cntr), maxs(cntr);

      exit when cols%notfound;

      if (types(cntr) = 'CHAR') then
         char_cnt := char_cnt + 1;
      elsif (types(cntr) = 'CLOB') then
         clob_cnt := clob_cnt + 1;
      elsif (types(cntr) = 'INT') then
         int_cnt := int_cnt + 1;
      else
         raise_application_error(-20000, 'illegal value for column type');
      end if;
        
      dbms_output.put_line (col_names(cntr) || ' ' || visibles(cntr));
      cntr := cntr+1;

    end loop;
    col_cnt := cntr-1;  -- cntr gets incremented one too many times

    -- Must have at least one column defined to continue

    if (col_cnt < 1) then
      raise_application_error (-20000, 
        'No columns defined for concatenated datastore ' || cdname);
    end if;

--dbms_output.put_line ('count is '||to_char(col_cnt));
--dbms_output.put_line('Counts: CHAR '||to_char(char_cnt)||' CLOB '||
--  to_char(clob_cnt)||' INT '||to_char(int_cnt));

    -- Assertion
    if (char_cnt + clob_cnt + int_cnt != col_cnt) then
      raise_application_error (-20000, 'problem with column count');
    end if;

    proc_buffer :=
    'create or replace procedure ' || cdname           || chr(10) ||
    '  (rid in rowid,'                                 || chr(10) ||
    '  tlob in out nocopy clob ) is'                   || chr(10) ||
    '  v_length                       integer;'        || chr(10) ||
    '  v_buffer                       varchar2(4000);' || chr(10);

    for cntr in 1..col_cnt loop

      proc_buffer := proc_buffer ||
        '  tag' || cntr || ' varchar2(30) := ''' || sec_names(cntr) || ''';' || chr(10);

    end loop;    

    for cntr in 1 .. char_cnt loop
      proc_buffer := proc_buffer || 
        '  vvc' || to_char(cntr) || ' varchar2(32767);' || chr(10);
    end loop;

    for cntr in 1 .. clob_cnt loop
      proc_buffer := proc_buffer ||
        '  vclob' || to_char(cntr) || ' clob;' || chr(10);
    end loop;

    for cntr in 1 .. int_cnt loop
      proc_buffer := proc_buffer ||
        'vint' || to_char(cntr) || ' integer;' || chr(10);
    end loop;

    proc_buffer := proc_buffer || '  begin' || chr(10);
 
    -- Generate the select statement

    select_clause := '';
    into_clause   := '';
    comma         := '';

    select_clause := ' SELECT ';
    into_clause   := ' INTO ';

    for cntr in 1 .. char_cnt loop
      select_clause := select_clause || comma || col_names(cntr);
      into_clause   := into_clause   || comma || 'vvc' || to_char(cntr);
      comma := ', ';
    end loop;

    for cntr in 1 .. clob_cnt loop
      select_clause := select_clause || comma || col_names(cntr+char_cnt);
      into_clause   := into_clause   || comma || 'vclob' || to_char(cntr);
      comma := ', ';
    end loop;

    for cntr in 1 .. int_cnt loop
      select_clause := select_clause || comma || col_names(cntr+char_cnt+clob_cnt);
      into_clause   := into_clause   || comma || 'vint' || to_char(cntr);
      comma := ', ';
    end loop;

    proc_buffer := proc_buffer || select_clause || into_clause || chr(10) ||
    ' from ' || username || '.' || tablename                   || chr(10) ||
    ' where rowid = rid;'                                      || chr(10) ||
    '  v_buffer := '''' '                                      || chr(10);

    for cntr in 1 .. char_cnt loop
      proc_buffer := proc_buffer ||  
                   ' || ' ||
        '          ''<''  || tag' || cntr || ' || ''>'' ||' || chr(10) ||
    '              vvc' || cntr || ' ||'                    || chr(10) ||
    '              ''</'' || tag' || cntr || ' || ''>'''    || chr(10);
    end loop;

    proc_buffer := proc_buffer || ';'       || chr(10) ||
    ''                                      || chr(10) ||
    '  v_length := length ( v_buffer );'    || chr(10) ||
    ''                                      || chr(10) ||
    '  Dbms_Lob.Trim'                       || chr(10) ||
    '    ('                                 || chr(10) ||
    '      lob_loc        => tlob,'         || chr(10) ||
    '      newlen         => 0'             || chr(10) ||
    '    );'                                || chr(10) ||
    ''                                      || chr(10);
    
    if (char_cnt > 0) then
      proc_buffer := proc_buffer ||
      '  Dbms_Lob.Write'                    || chr(10) ||
      '    ('                               || chr(10) ||
      '      lob_loc        => tlob,'       || chr(10) ||
      '      amount         => v_length,'   || chr(10) ||
      '      offset         => 1,'          || chr(10) ||
      '      buffer         => v_buffer'    || chr(10) ||
      '    );'                              || chr(10);
    end if;

    for cntr in 1..clob_cnt loop
      proc_buffer := proc_buffer ||
        '  Dbms_Lob.WriteAppend'                           || chr(10) ||
        '    ('                                            || chr(10) ||
        '      lob_loc  => tlob,'                          || chr(10) ||
        '      amount   => length ( ''<''' || 
        '|| tag' || to_char(char_cnt+cntr) || '||''>'' ),' || chr(10) ||
        '      buffer   => ''<''' || 
        '|| tag' || to_char(char_cnt+cntr) || '||''>'''    || chr(10) ||
        '    );'                                           || chr(10) ||
        '  Dbms_Lob.Copy'                                  || chr(10) ||
        '    ('                                            || chr(10) ||
        '      dest_lob      => tlob,'                     || chr(10) ||
        '      src_lob       => vclob'|| cntr || ','       || chr(10) ||
        '      amount        => Dbms_Lob.GetLength (vclob' || cntr ||
        '),'                                               || chr(10) ||
        '      dest_offset   => Dbms_Lob.GetLength (tlob)+1,'|| chr(10) ||
        '      src_offset    => 1'                         || chr(10) ||
        '    );'                                           || chr(10) ||
        ''                                                 || chr(10) ||
        '  Dbms_Lob.WriteAppend'                           || chr(10) ||
        '    ('                                            || chr(10) ||
        '      lob_loc  => tlob,'                          || chr(10) ||
        '      amount   => length ( ''</''' || 
        '|| tag' || to_char(char_cnt+cntr) || '||''>'' ),' || chr(10) ||
        '      buffer   => ''</''' || 
        '|| tag' || to_char(char_cnt+cntr) || '||''>'''    || chr(10) ||
        '    );'                                       || chr(10);
    end loop;
    proc_buffer := proc_buffer || 'end;';  

-- FOR DEBUGGING: Needs table CREATE TABLE TRACE_SOURCE (PROC_BUFFER CLOB)
-- This allows you to inspect the generated procedure from SQL*Plus
-- remember to SET LONG 20000 or similar

    delete from trace_source;
    insert into trace_source values (proc_buffer);

-- END DEBUGGING CODE
    
    execute immediate proc_buffer;
  
    execute immediate 
       ('grant execute on ' || cdname || ' to ' || username);

    -- Create the datastore (delete first but ignore "does not exist" err)
    begin
      execute immediate
       ('begin ctx_ddl.drop_preference(''' || cdname || ''') ; end ;');
    exception
      when others then
        null;
    end;

    execute immediate
       ('begin '                                                 ||
          'ctx_ddl.create_preference '                           || 
          '( ''' || cdname || ''', ''user_datastore'' ); '   ||
          'ctx_ddl.set_attribute '                               || 
          '( ''' || cdname || ''', ''procedure'',''' || cdname ||''' ); ' ||
        'end;');

  -- Now create the section group and sections

  -- Create the section group
  -- Delete it first, ignoring errors if it doesn't exist
  begin
    execute immediate (
      'begin ctx_ddl.drop_section_group '        ||
        '(group_name  => ''' || cdname || ''') ; end ; ');
  exception
    when others then
      null;
  end;

  execute immediate (
    'begin ctx_ddl.create_section_group ('     ||
      'group_name   => ''' || cdname || ''', ' ||
      'group_type   => ''basic_section_group'') ; end ; ');

--  dbms_output.put_line ('*** creating section definitions');
--  dbms_output.put_line ('*** column count is '||col_cnt);
 
  for cntr in 1 .. col_cnt loop
    -- No section tags if sec_names(col) is empty
--    dbms_output.put_line ('*** section name : '|| sec_names(cntr));
    if (length(sec_names(cntr)) > 0) then
      proc_buffer := 
        'begin ctx_ddl.add_field_section ('                  || chr(10) ||
        '  group_name   => ''' || cdname           || ''','  || chr(10) ||
        '  section_name => ''' || sec_names(cntr)  || ''','  || chr(10) ||
        '  tag          => ''' || sec_names(cntr)  || ''','  || chr(10);
      if (visibles(cntr) = 'Y') then
        proc_buffer := proc_buffer || '  visible      => true ) ; end ; ';
      else
        proc_buffer := proc_buffer || '  visible      => false ) ; end ; ';
      end if;
-- DEBUG CODE
      insert into trace_source values (proc_buffer);
-- END DEBUG CODE
      execute immediate (proc_buffer);
    end if;
  end loop;
  end do_dynamic_setup;

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
 
    do_dynamic_setup (l_cdstore_name, l_user, tab);
 
  end create_cdstore;
 
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

    -- Check name is valid
    if (not (identifier_is_valid(l_cdstore))) then
      raise_application_error (-20000, 
        'illegal characters in concatenated datastore name '|| l_cdstore);
    end if;

    -- Check it doesn't already exist
    select count(*) into cnt from ctx_cdstores
    where cdstore_name = l_cdstore;

    if (cnt > 0) then
      raise_application_error 
        (-20000, 'name already in use for concatenated datastore - possibly by another user');
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

    -- Check value for col_type - only support CHAR and CLOB
    -- at this time

    if (l_col_type != 'CHAR' and l_col_type != 'CLOB') then
      raise_application_error (-20000,
        'col_type ' || l_col_type || ' invalid - use CHAR or CLOB');
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
           (-20000, 'concatenated datastore ' || l_name || ' does not exist');
    end;

    -- Validated that cdstore exists OK
    -- now store col data

    insert into ctx_cdstore_cols (
      cdstore_id, col_name, section_name, visible, col_type, min_val, max_val)
     values (
      id, l_col_name, l_sec_name, l_visible, l_col_type, l_min_val, l_max_val);
   
    -- Now do the actual creation

    create_cdstore(l_name);
  end;

  procedure drop_cdstore(
     cdstore_name varchar2) is
    id              number;
    l_name          varchar2(30);
    no_such_object  exception;
    pragma exception_init(no_such_object, -4043);
  begin
    begin
      l_name := upper(cdstore_name);
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
         ('begin ctx_ddl.drop_preference(''' || l_name || ''') ; end ;');
    exception
      when others then
        null;
    end;

    -- drop the procedure
    begin
      execute immediate
        ('drop procedure '||l_name);
    exception
      when no_such_object then
        null;
    end;

    -- Drop the section group
    begin
      execute immediate (
        'begin ctx_ddl.drop_section_group '        ||
          '(group_name  => ''' || l_name || ''') ; end ; ');
    exception
      when others then
        null;
    end;

  exception
    when no_data_found then
      null;
  end;

  -- private function
  -- Create the datastore procedure

 --  procedure create_section_group (cdname varchar2, username varchar2, tablename varchar2) is

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
exec dbms_output.enable(65000)
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
    col_name     => 'author',
    col_type     => 'char');
end;
/
exec ctx_cd.add_column     ('my_cdstore', 'title')
exec ctx_cd.add_column     ('my_cdstore', 'abstract', col_type=>'clob')

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


