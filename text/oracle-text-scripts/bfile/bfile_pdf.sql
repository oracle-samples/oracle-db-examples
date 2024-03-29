-- example of indexing a PDF document using a BFILE to access a file system
-- document. 
-- Also shows extraction of document contents as HTML

-- You will need to provide your own PDF document
-- Lines that need to be changed for your DBS password, directory, document 
-- name and search terms are clearly marked.

set echo on

-- CHANGE THIS LINE FOR DBA LOGIN

connect sys/oracle as sysdba

drop user demouser cascade;
create user demouser identified by demouser;

grant connect,resource,ctxapp,unlimited tablespace,create any directory to demouser;

connect demouser/demouser

set serveroutput on

-- WARNING: case is SENSITIVE for directory name MY_BFILE_DIRECTORY
-- either put it in double quotes or use upper case when used later.

-- CHANGE THIS LINE FOR DIRECTORY:

create or replace directory MY_BFILE_DIRECTORY as '/home/oracle/docs';

-- drop table my_table;
create table my_table (id number primary key, text bfile);

-- CHANGE THIS LINE FOR FILE NAME

insert into my_table values (1, bfilename('MY_BFILE_DIRECTORY', 'David-Malpass.pdf'));

create index my_index on my_table(text)
indextype is ctxsys.context
parameters('filter ctxsys.auto_filter');

select * from ctx_user_index_errors where err_index_name = 'MY_INDEX';

-- run a query
-- CHANGE THIS LINE TO SOMETHING THAT EXISTS IN YOUR PDF

select id, dbms_lob.getlength(text) from my_table 
where contains (text, 'economy') > 0;

-- get content of document as HTML

-- sqlplus bind variable - may or may not work in SQL Developer
variable c clob;

declare
  rid rowid;
begin
  -- fetch the rowid value and use it in ctx_doc.filter
  select rowid into rid from my_table where id = 1;
  ctx_doc.set_key_type('ROWID');
  dbms_lob.createtemporary(:c, true);
  ctx_doc.filter('my_index', rid, :c); 
end;
/

set pagesize 1000
set linesize 130
set long 500000
column c format a130
print c

