set timing on
set echo on

drop index bike_items_idx2;

exec ctx_output.start_log('rogerUDP_p');

alter session enable parallel dml;
alter session enable parallel ddl;
alter session enable parallel query;
alter session set sql_trace=true;

exec ctx_ddl.drop_preference('myuds');
exec ctx_ddl.create_preference('myuds', 'user_datastore');
exec ctx_ddl.set_attribute('myuds', 'procedure', 'My_Proc');

create index bike_items_idx2 on bike_items_p2 (descrip)
indextype is ctxsys.context parallel 16;

alter session set sql_trace=false;

exec ctx_output.end_log;
