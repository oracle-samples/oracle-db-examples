drop table concat_table;
create table concat_table (
  pk number primary key,
  title varchar2(2000),
  author varchar2(2000),
  concat varchar2(1),
  abstract clob
);

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

connect ctxsys/ctxsys

create or replace procedure p$c@g:\auser\sql\concatoncat_table
 (rid in rowid,
  tlob in out nocopy clob ) is
 tag1 varchar2(2000) := 'title';
 tag2 varchar2(2000) := 'author';
 tag3 varchar2(2000) := 'abstract';
 vvc1 varchar2(32767);
 vvc2 varchar2(32767);
 vclob clob;
 v_buffer                       varchar2(4000);
 v_length                       integer;
begin
select title, author, abstract
    into vvc1, vvc2, vclob
    from roger.concat_table where rowid = rid;

  v_buffer := 
              '<'  || tag1 || '>' ||
              vvc1 ||
              '</' || tag1 || '>' ||
              '<'  || tag2 || '>' ||
              vvc2 ||
              '</' || tag2 || '>' ||
              '< ' || tag3 || '>';

  v_length := length ( v_buffer );

  Dbms_Lob.Trim
    (
      lob_loc        => tlob,
      newlen         => 0
    );

  Dbms_Lob.Write
    (
      lob_loc        => tlob,
      amount         => v_length,
      offset         => 1,
      buffer         => v_buffer
    );

  Dbms_Lob.Copy
    (
      dest_lob      => tlob,
      src_lob       => vclob,
      amount        => Dbms_Lob.GetLength ( vclob ),
      dest_offset   => v_length + 1,
      src_offset    => 1
    );

  Dbms_Lob.WriteAppend
    (
      lob_loc  => tlob,
      amount   => length ( '</' || tag3 || '>' ),
      buffer   => '</' || tag3 || '>'
    );
end;
/
list
show errors
grant execute on p$concat_table to roger;

connect roger/roger
set serverout on

/* TESTING CODE */

declare
  tlob clob;
  buff varchar2(4000);
  amnt integer;
begin
  for j in
    (
      select rowid from concat_table
    )
  loop
    /* this is what the ctx calling env does */
    Dbms_Lob.CreateTemporary
      (
        lob_loc => tlob,
        cache   => true,
        dur     => Dbms_Lob.Session
      );

    ctxsys.p$concat_table ( j.rowid, tlob );

    amnt := 4000;
    Dbms_Lob.Read
      (
        lob_loc => tlob,
        amount  => amnt,
        offset  => 1,
        buffer  => buff
      );
    Dbms_Output.Put_Line ( buff );

    /* this is again what the ctx calling env does */
    Dbms_Lob.FreeTemporary
      (
        lob_loc => tlob
      );
  end loop;
end;
/

/* PREFERENCES, SECTION GROUPS AND INDEX */

connect roger/roger
begin
  ctx_ddl.drop_preference ( 'd$concat_table' );
end;
/
begin
  ctx_ddl.create_preference ( 'd$concat_table', 'user_datastore' );
  ctx_ddl.set_attribute ( 'd$concat_table', 'procedure','p$concat_table' );
end;
/

begin
  ctx_ddl.drop_preference
    (
      preference_name => 'my_basic_lexer'
    );
end;
/
begin
  ctx_ddl.create_preference
    (
      preference_name => 'my_basic_lexer',
      object_name     => 'basic_lexer'
    );
  ctx_ddl.set_attribute
    (
      preference_name => 'my_basic_lexer',
      attribute_name  => 'index_text',
      attribute_value => 'true'
    );
  ctx_ddl.set_attribute
    (
      preference_name => 'my_basic_lexer',
      attribute_name  => 'index_themes',
      attribute_value => 'false');
end;
/

begin
  ctx_ddl.drop_section_group
    (
       group_name => 's$concat_table'
    );
end;
/
begin
  ctx_ddl.create_section_group
    (
       group_name => 's$concat_table',
       group_type => 'basic_section_group'
    );
  ctx_ddl.add_field_section
    (
      group_name   => 's$concat_table',
      section_name => 'title',
      tag          => 'title',
      visible      => true /* this is the DEFAULT */
    );
  ctx_ddl.add_field_section
    (
      group_name   => 's$concat_table',
      section_name => 'author',
      tag          => 'author',
      visible      => true /* this is the DEFAULT */
    );
  ctx_ddl.add_field_section
    (
      group_name   => 's$concat_table',
      section_name => 'abstract',
      tag          => 'abstract',
      visible      => true /* this is the DEFAULT */
    );
end;
/

drop index i$concat_table;

select err_text from ctx_user_index_errors;

-- Note: Bug #881851 at 8.1.5 can cause problems here.
-- The following "create index" stmt will work only ONCE
-- in a given session. If you drop the index and try
-- "create index" for a second time in the same session
-- you'll get...
--
--   DRG-50857: oracle error in drsinopen
--   DRG-50858: OCI error: OCI_INVALID_HANDLE
--
-- in CTX_USER_INDEX_ERRORS. The workaround is to
-- exit the session and connect to a new one.
--
-- Bug #881851 is fixed in 8.1.6 and backported to 8.1.5.1.

create index i$concat_table on concat_table ( concat )
  indextype is ctxsys.context
  parameters ( 'datastore d$concat_table lexer my_basic_lexer section group s$concat_table' );
select err_text from ctx_user_index_errors;

create or replace trigger t$concat_table
  /*
    In this example we don't need to consider
    delete or insert because the user_datastore
    prcedure accesses only other fields in the
    same row as the dummy indexed field
  */
  before update
  on concat_table
  for each row
begin
  :new.concat := 'x';
  insert into trace_table values (:old.concat, sysdate);
  insert into trace_table values (:new.concat, sysdate);
end;
/
select abstract from concat_table where contains (concat, 'beer within title') > 0;

/* need to reconnect to avoid bug */

connect roger/roger

update concat_table set title = 'Red wine and me' where pk=3;

select pnd_index_name, pk
  from ctx_user_pending, concat_table
  where pnd_rowid = concat_table.rowid;

alter index i$concat_table rebuild online parameters ('sync');

select abstract from concat_table where contains (concat, 'beer within title') > 0;

select abstract from concat_table where contains (concat, 'wine within title') > 0;






