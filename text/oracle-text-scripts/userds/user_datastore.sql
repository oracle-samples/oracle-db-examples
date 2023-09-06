-- user datastore examples

connect sys/telstar as sysdba

drop user testuser cascade;

create user testuser identified by testuser default tablespace users temporary tablespace temp quota unlimited on users;

grant connect,resource,ctxapp to testuser
/

connect testuser/testuser 

-- first example takes two names - first and last - and concatenates them into
-- a full name for indexing.

create table my_tab ( first varchar2(30), last varchar2(30) )
/

insert into my_tab values ( 'John', 'Smith' )
/
insert into my_tab values ( 'Bill', 'Bloggs' )
/

create or replace procedure my_proc ( 
   rid in rowid,
   clb in out nocopy clob 
) is
   v_first varchar2(30);
   v_last  varchar2(30);   
begin

   select first, last into v_first, v_last 
   from my_tab
   where rowid = rid;

   clb := v_first || ' ' || v_last;

end my_proc;
/
show err

-- this next bit shows how we can debug our user_datastore procedure by calling it
-- manually for each row in our table (we can limit how many rows using rownum)

set serveroutput on size 1000000

declare
  my_clob CLOB;
begin
  for csr in (select rowid from my_tab where rownum < 100) loop
    -- create an empty LOB for the user datastore to fill
    dbms_lob.createtemporary (my_clob, true);
    my_proc (csr.rowid, my_clob);
    dbms_output.put_line('Datastore output (first 80 chars) for rowid '||csr.rowid||' is: '||substr(my_clob,1,80));
  end loop;
end;
/

begin
   ctx_ddl.create_preference( 'my_ds_pref', 'USER_DATASTORE' );
   ctx_ddl.set_attribute    ( 'my_ds_pref', 'PROCEDURE', 'my_proc' );
end;
/

-- notice the index is (arbitrarily) on 'first' column, though both columns will be indexed
create index my_index on my_tab ( first ) 
indextype is ctxsys.context
parameters ( 'datastore my_ds_pref' )
/

-- do a query
select * from my_tab where contains ( first, 'bloggs' ) > 0
/

-- do an insert
insert into my_tab values ('Fred', 'Flintstone')
/

-- search for new row - won't find it as index not sync'd

select * from my_tab where contains ( first, 'flintstone' ) > 0
/

-- sync and search again

exec ctx_ddl.sync_index ('my_index')

select * from my_tab where contains ( first, 'flintstone' ) > 0
/

-- now change the user datastore to turn all names into pseudo-Russian

create or replace procedure my_proc ( 
   rid in rowid,
   clb in out nocopy clob 
) is
   v_first varchar2(30);
   v_last  varchar2(30);   
begin

   select first, last into v_first, v_last 
   from my_tab
   where rowid = rid;

   clb := v_first || ' ' || v_last || 'ski';
   --          changed:            ^^^^^^^^
end my_proc;
/

-- no effect immediately

select * from my_tab where contains ( first, 'smithski' ) > 0
/

-- but update a row, sync, and try again

update my_tab set first = first where first = 'John';
 
exec ctx_ddl.sync_index ('my_index')

-- we can find 'smithski' in index, even though it's in the original data, because
-- our user datastore modified the text
select * from my_tab where contains ( first, 'smithski' ) > 0
/
