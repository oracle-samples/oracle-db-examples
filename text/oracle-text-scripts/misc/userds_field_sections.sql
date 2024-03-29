-- load a binary file to the db
-- user running this must have CREATE ANY DIRECTORY privilege
-- change the directory name below to suit your directory

create or replace directory MYDOCDIR as 'c:\docs';

drop table mydocs;
create table mydocs (filename varchar2(200), text_col blob, permissions varchar2(2000));


-- create the procedure for loading files into a BLOB column

create or replace procedure loadDoc( filename varchar2, permissions varchar2 ) is
  src_blob bfile := bfilename('MYDOCDIR', filename);
  dest_blob blob;
begin
  insert into mydocs values (filename, empty_blob(), permissions) returning text_col into dest_blob;
  dbms_lob.open(src_blob, dbms_lob.lob_readonly);
  dbms_lob.loadFromFile(
     dest_lob => dest_blob,
     src_lob => src_blob,
     amount => dbms_lob.getlength(src_blob)
  );
  dbms_lob.close(src_blob);
  commit;
end;
/
show errors

-- use it to load a file

exec loadDoc( '1.pdf', 'Uroger Gmanagers Gsales' )

-- A simple index on this table WITHOUT using the user datastore

create index mydocs_index on mydocs(text_col) indextype is ctxsys.context
parameters ('datastore ctxsys.direct_datastore filter ctxsys.inso_filter');

-- test it

select filename from mydocs where contains( text_col, 'quota' ) > 0;

-- Now create the user datastore procedure
-- This user datastore will
--   1/ Get the BLOB from the database for the current row
--   2/ Decrypt it using DBMS_CRYPTO (not implemented for this example)
--   3/ Pass it through the filter

create or replace procedure my_proc 
     (rid in rowid, tlob in out nocopy clob) is 
     tempblob blob;
     perm varchar2(2000);
begin 
     dbms_lob.createtemporary(tempblob, true);
     -- dbms_lob.createtemporary(tempclob, true);

     -- get the blob from the database
     select text_col, permissions into tempblob, perm from mydocs where rowid = rid;
     
     -- decrypt it here
     -- NOT IMPLEMENTED!

     -- then filter it
     ctx_doc.ifilter(tempblob, tlob);

     dbms_lob.append(tlob, '<permissions>' || perm || '</permissions>');

     -- text is returned in tlob parameter
end; 
/
show errors

exec ctx_ddl.drop_preference('my_datastore')
exec ctx_ddl.drop_section_group('my_sections')

exec ctx_ddl.create_preference('my_datastore', 'user_datastore')
exec ctx_ddl.set_attribute('my_datastore', 'procedure', 'my_proc')

exec ctx_ddl.create_section_group('my_sections', 'basic_section_group')
exec ctx_ddl.add_field_section('my_sections', 'permissions', 'permissions')

-- create another index, this time using the user_datastore
-- we'll create the index on the filename column, but since we're 
-- using a user datastore it could be any column

create index mydocs_index2 on mydocs(filename) indextype is ctxsys.context
parameters ('datastore my_datastore filter ctxsys.null_filter section group my_sections');

-- test it

select filename from mydocs where contains( filename, 'quota and Uroger within permissions' ) > 0;
select filename from mydocs where contains( filename, 'quota and Ubill within permissions' ) > 0;
select filename from mydocs where contains( filename, 'quota and Gmanagers within permissions' ) > 0;

