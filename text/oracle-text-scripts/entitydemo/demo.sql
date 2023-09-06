
-- 1) Index documents (PDF, MSWord, RTF, etc) in both the database and filesystem

--  ON FILESYSTEM

drop table mydocs
/
create table mydocs 
   ( filename varchar2(80) )
/

exec ctx_ddl.drop_preference  ( 'my_file_ds' )
exec ctx_ddl.create_preference( 'my_file_ds', 'FILE_DATASTORE' )

insert into mydocs values( 'K:\auser\data\WordFiles\Word2007Documents\00d3b040.docx' );
insert into mydocs values( 'K:\auser\data\PDF\2013920_Motorsport_Awards_Booking_Form_2013.pdf' );
insert into mydocs values( 'K:\auser\data\PDF\Final Draft CGRC Dinner Invite-1.pdf' );

create index mydocs_index on mydocs( filename )
indextype is ctxsys.context
parameters( 'datastore my_file_ds' )
/

select * from ctx_user_index_errors;

select * from mydocs where contains( filename, 'caterham' ) > 0;

-- IN DATABASE

drop table mydocs
/

create table mydocs 
   ( filename varchar2(80),  
     filedata blob )
/

host sqlldr roger/roger control=loader.ctl

create index mydocs_index on mydocs( filedata )
indextype is ctxsys.context
parameters( '' )
/

select filename from mydocs where contains( filedata, 'dinner' ) > 0;

-- 2) Creation of a simple(?) thesaurus of 'dirty words' with update capability.

exec ctx_thes.drop_thesaurus( 'default' )

host ctxload -user roger/roger -thes -name default -file synonyms.ths

select filename from mydocs where contains( filedata, 'syn(supper)' ) > 0;

-- update the thesaurus to add another term to synonym ring for DINNER

exec ctx_thes.create_relation('DEFAULT', 'DINNER', 'SYN', 'FOOD')

-- select the HTML snippet of the result with search terms highlighted in bold:

select ctx_doc.snippet('mydocs_index', rowid, 
'syn(food)') from mydocs where contains( filedata, 'syn(food)' ) > 0;

-- basic fetch of the document text

variable myclob clob

begin
   for c in ( select rowid from mydocs where contains( filedata, 'syn(food)' ) > 0 ) loop
      dbms_lob.createtemporary( :myclob, true );
      ctx_doc.filter( 'mydocs_index', c.rowid, :myclob, true );
   end loop;
end;
/

set long 500000
print myclob

