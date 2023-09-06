connect sys/telstar as sysdba

drop user testuser cascade;

create user testuser identified by testuser default tablespace users temporary tablespace temp quota unlimited on users;

grant connect,resource,ctxapp to testuser
/

connect testuser/testuser 

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
   v_clb  clob;
begin

   dbms_lob.trim(clb, 0);

   select first || last into v_clb 
   from my_tab
   where rowid = rid
   and 1 = 2;

   if not (v_clb is null or dbms_lob.getlength(v_clb) < 1) then
     dbms_lob.trim(clb, 0);
     dbms_lob.copy(clb, v_clb, 1, 1);
   end if;

end my_proc;
/
show err

begin
   ctx_ddl.create_preference( 'my_ds_pref', 'USER_DATASTORE' );
   ctx_ddl.set_attribute    ( 'my_ds_pref', 'PROCEDURE', 'my_proc' );
end;
/

create index my_index on my_tab ( first ) 
indextype is ctxsys.context
parameters ( 'datastore my_ds_pref' )
/

select * from ctx_user_index_errors;

select * from dr$my_index$k;
