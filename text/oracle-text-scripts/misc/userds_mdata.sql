-- load a binary file to the db
-- user running this must have CREATE ANY DIRECTORY privilege
-- change the directory name below to suit your directory

create or replace directory MYDOCDIR as 'c:\docs';

drop table mydocs;
drop table permissions;

create table mydocs (filename varchar2(200), text_col blob);

create table permissions (filename varchar2(200), allowuser varchar2(200), allowgroup varchar2(200));

-- create the procedure for loading files into a BLOB column

create or replace procedure loadDoc( filename varchar2 ) is
  src_blob bfile := bfilename('MYDOCDIR', filename);
  dest_blob blob;
begin
  insert into mydocs values (filename, empty_blob()) returning text_col into dest_blob;
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

exec loadDoc( '1.pdf' )
insert into permissions values ('1.pdf', 'roger', null);
insert into permissions values ('1.pdf', null, 'managers');
insert into permissions values ('1.pdf', null, 'sales');

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
     thefile varchar2(2000);
     permissions varchar2(32767) := '';
begin 
     dbms_lob.createtemporary(tempblob, true);
     -- dbms_lob.createtemporary(tempclob, true);

     -- get the blob from the database
     select text_col, filename into tempblob, thefile from mydocs where rowid = rid;
     
     -- decrypt it here
     -- NOT IMPLEMENTED!

     -- then filter it
     ctx_doc.ifilter(tempblob, tlob);

     for csr in ( select allowuser, allowgroup from permissions where filename = thefile ) loop
          if( csr.allowuser is not null ) then
               permissions := permissions || '<permissions>U' || csr.allowuser || '</permissions>';
          end if;

          if( csr.allowgroup is not null ) then
               permissions := permissions || '<permissions>G' || csr.allowgroup || '</permissions>';
          end if;
     end loop;

     -- The "permissions" string contains our ACL. Append it to the document before indexing
     dbms_lob.append( tlob, permissions );

     -- text is returned in tlob parameter
end; 
/
show errors

exec ctx_ddl.drop_preference('my_datastore')
exec ctx_ddl.drop_section_group('my_sections')

exec ctx_ddl.create_preference('my_datastore', 'user_datastore')
exec ctx_ddl.set_attribute('my_datastore', 'procedure', 'my_proc')

exec ctx_ddl.create_section_group('my_sections', 'basic_section_group')
exec ctx_ddl.add_mdata_section('my_sections', 'permissions', 'permissions')

-- create another index, this time using the user_datastore
-- we'll create the index on the filename column, but since we're 
-- using a user datastore it could be any column

create index mydocs_index2 on mydocs(filename) indextype is ctxsys.context
parameters ('datastore my_datastore filter ctxsys.null_filter section group my_sections');

-- test it

-- this query should work - user roger is allowed to see the doc
select filename from mydocs where contains( filename, 'quota and mdata(permissions, Uroger)') > 0;
-- this query should NOT work, user bill is not allowed to see the doc
select filename from mydocs where contains( filename, 'quota and mdata(permissions, Ubill)' ) > 0;
-- this query should work, group managers is allowed
select filename from mydocs where contains( filename, 'quota and mdata(permissions, Gmanagers)' ) > 0;
-- this query should work, group sales is allowed
select filename from mydocs where contains( filename, 'quota and mdata(permissions, Gsales)' ) > 0;

-- let's just take a look at the MDATA section values
select token_text, token_type from dr$mydocs_index2$i where token_type != '0';

