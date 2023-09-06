-- example of an Oracle Text  user datastore than fetches data from a file, 
-- filters it and combines it with other column data for indexing

-- this code may be freely reused

connect system/password

drop user testuser cascade;

create user testuser identified by testuser default tablespace users temporary tablespace temp quota unlimited on users;

grant connect,resource,create any directory,drop any directory to testuser;

connect testuser/testuser

-- for Windows
define FILESEP=\
-- for Linux
-- define FILESEP=/

-- drop sequence tempseq;

create sequence tempseq;

-- drop table example;

create table example
 (id        number primary key,
  document varchar2(255),
  metadata varchar2(255),
  content  varchar2(255),
  dummycol varchar2(1)
 );

insert into example values (
  1,
  'C:\docs\dir1\abc.docx',
  'Electric',
  'Electrical',
  'X' );
insert into example values (
  1,
  'C:\docs\dir1\abc.docx',
  'Electrical',
  'Electric',
  'X' );
insert into example values (
  5,
  'C:\docs\dir2\test1.pdf',
  'Electrical Nuclear',
  'Electrical',
  'X' );

exec ctx_ddl.create_policy ( 'mypol', 'CTXSYS.AUTO_FILTER')

-- procedure to create a unique name
create or replace function tempname return varchar2 is 
begin
  -- must be upper case if used as directory name
  return 'TMP$DIR$' || tempseq.nextval;
end;
/

-- procedures to split file name into path and file

CREATE or REPLACE function get_filename
   (p_path IN VARCHAR2)
   RETURN varchar2
IS
   v_file VARCHAR2(100);
BEGIN
   IF INSTR(p_path,'&FILESEP') > 0 THEN
      v_file := SUBSTR(p_path,(INSTR(p_path,'&FILESEP',-1,1)+1),length(p_path));

   -- If no slashes were found, return the original string
   ELSE
      v_file := p_path;
   END IF;
   RETURN v_file;
END;
/

CREATE or REPLACE function get_filepath
   (p_path IN VARCHAR2)
   RETURN varchar2
IS
   v_file VARCHAR2(100);
BEGIN
   IF INSTR(p_path,'&FILESEP') > 0 THEN
      v_file := SUBSTR(p_path,1,(INSTR(p_path,'&FILESEP',-1,1)-1));

   -- If no slashes were found, return empty value
   ELSE
      v_file := '';
   END IF;
   RETURN v_file;
END;
/

create or replace procedure ex_datastore (rid rowid, clobout in out nocopy clob) is
  v_doc   varchar2(255);
  v_meta  varchar2(255);
  v_cont  varchar2(255);
  dirname varchar2(30);
  dirpath varchar2(255);
  filname varchar2(255);
  tmpclob clob;
  binfile bfile;
  amount number := 32767;
  position number := 1;
  buffer raw(32767);
begin

  select document, metadata, content into v_doc, v_meta, v_cont
  from example where rowid = rid;

  -- find the path from the filename and use it to create a directory
  dirname := tempname();
  dirpath := get_filepath(v_doc);
  filname := get_filename(v_doc);

  -- delete left-over directory with same name
  begin
    execute immediate ('DROP DIRECTORY ' || dirname );
  exception
    when others then  -- should really pick up "directory does not exist" only
      null;
  end;

  execute immediate ('CREATE DIRECTORY ' || dirname || ' AS ''' || dirpath || '''');
  dbms_output.put_line ('CREATE DIRECTORY ' || dirname || ' AS ''' || dirpath || '''');
  
  clobout := '<metadata>' || v_meta || '</metdata>';
  clobout := clobout || '<content>' || v_cont || '</content>';

  -- initialize the temp lob
  dbms_lob.createtemporary( tmpclob, TRUE );

  -- get the binary doc as a bfile
  binfile := bfilename( dirname, filname ); 

  -- filter the binary file
  ctx_doc.policy_filter 
     (  policy_name => 'mypol',
        document    => binfile,
        restab      => tmpclob );

  clobout := clobout || '<document>' || tmpclob || '</document>';

  -- clean up
  execute immediate ('DROP DIRECTORY ' || dirname );

end ex_datastore;
/
list
show errors

exec ctx_ddl.create_preference('myds', 'USER_DATASTORE')
exec ctx_ddl.set_attribute('myds', 'PROCEDURE', 'ex_datastore')

-- this part only necessary if you want to search on specific columns
exec ctx_ddl.create_section_group('mygrp', 'BASIC_SECTION_GROUP')
exec ctx_ddl.add_field_section   ('mygrp', 'document', 'document', true) 
exec ctx_ddl.add_field_section   ('mygrp', 'metadata', 'metadata', true) 
exec ctx_ddl.add_field_section   ('mygrp', 'content',  'content',  true) 

set serverout on

create index ex_index on example(dummycol)
indextype is ctxsys.context
parameters ('datastore myds section group mygrp')
/

select * from ctx_user_index_errors;

column document format a30
column metadata format a20
column content  format a20

set echo on

-- just find electrical anywhere
select document,metadata,content from example
where contains (dummycol, 'electrical') > 0;

-- electrical AND nuclear anywhere
select document,metadata,content from example 
where contains (dummycol, 'electrical AND nuclear') > 0;

-- nuclear only in metadata
select document,metadata,content from example 
where contains (dummycol, 'nuclear WITHIN metadata') > 0;
