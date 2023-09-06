set timing on
set echo on

drop index bike_items_idx2;

exec ctx_output.start_log('roger4_p');

alter session enable parallel dml;
alter session enable parallel ddl;
alter session enable parallel query;
alter session set sql_trace=true;

create index bike_items_idx2 on bike_items_p2 (descrip)
indextype is ctxsys.context parallel 16;

alter session set sql_trace=false;

exec ctx_output.end_log;
