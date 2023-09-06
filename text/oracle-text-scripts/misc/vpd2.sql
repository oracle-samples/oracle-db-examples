connect sys/welcome1 as sysdba

drop user vpdtest cascade;

create user vpdtest identified by vpdtest default tablespace users temporary tablespace temp;
grant connect,resource,ctxapp to vpdtest;
grant execute on dbms_rls to vpdtest;

connect vpdtest/vpdtest

--drop table orders;
--drop table shadow;

create table orders (
  order_id number,
  order_detail varchar2(2000),
  sales_rep_id number
);
create table shadow (
  order_id number,
  dummy    varchar2(1)
);

grant select on orders to ctxsys;
grant select on shadow to ctxsys;

insert into orders values (1, 'the quick brown fox', 159);
insert into shadow values (1, 'x');
insert into orders values (2, 'jumps over the lazy dog', 160);
insert into shadow values (2, 'x');

connect sys/welcome1 as sysdba

-- create the authorization function
-- should allow non-dba users to only see row 1 in our orders table

create or replace function auth_orders( 
  schema_var in varchar2,
  table_var in varchar2
) return varchar2 is
  return_val varchar2(4000);
begin
  return_val := 'SALES_REP_ID = 159';
  return return_val;
end auth_orders;
/

--begin
--  dbms_rls.drop_policy (
--    object_schema   => 'vpdtest',
--    object_name     => 'orders',
--    policy_name     => 'orders_policy'
--  );
--end;
--/

-- create the VPD policy using the auth_orders function

begin
  dbms_rls.add_policy (
    object_schema   => 'vpdtest',
    object_name     => 'orders',
    policy_name     => 'orders_policy',
    function_schema => 'sys',
    policy_function => 'auth_orders',
    statement_types => 'select, insert, update, delete'
  );
end;
/

connect vpdtest/vpdtest

-- test the VPD policy is working correctly

column order_detail format a30
prompt
prompt Selecting from table as user vpdtest
prompt
select rowid from orders;
connect sys/welcome1 as sysdba
prompt
prompt Selecting from table as user sys
prompt
select rowid from vpdtest.orders;

connect vpdtest/vpdtest

-- create the user datastore

create or replace procedure user_ds_proc(rid in rowid, outc in out nocopy clob) is
begin
  for c in (select order_id from vpdtest.shadow where rowid = rid ) loop
     begin
       select order_detail into outc from vpdtest.orders o where o.order_id = c.order_id;
     exception when no_data_found then 
       outc := 'NoDataFound for order_id '||c.order_id;
     end;
  end loop;
end;
/
list
show error

-- test the user datastore procedure
-- we expect to see "the quick brown fox" followed by "noDataFound for order_id 2"

set serveroutput on

declare
  clb clob;
  rid rowid;
begin
  dbms_lob.createtemporary( clb, true );
  for c in ( select rowid from vpdtest.shadow ) loop
    rid := c.rowid;
    user_ds_proc( rid, clb );
    dbms_output.put_line( clb );
  end loop;
end;
/

-- create the index using the user_datastore we just tested

exec ctx_ddl.create_preference('my_ds', 'user_datastore')
exec ctx_ddl.set_attribute('my_ds', 'procedure', 'user_ds_proc')

create index shadow_index on shadow (dummy) indextype is ctxsys.context
parameters ('datastore my_ds')
/

-- check for indexing errors

select * from ctx_user_index_errors;

-- check the indexed tokens
-- we expect to only see "quick brown fox", not "jumps over lazy dog"
select token_text from dr$shadow_index$i;

-- this should work
select * from shadow where contains (dummy, 'fox') > 0;

-- this should NOT work, but does
select * from shadow where contains (dummy, 'dog') > 0;

-- Now create a standard index on the VPD'd table

create index orders_index on orders(order_detail) indextype is ctxsys.context
parameters('datastore ctxsys.direct_datastore')
/

select token_text from dr$orders_index$i;
