connect roger/roger

create table starofficetest (pk number primary key, thefile varchar2(2000));
insert into starofficetest values (1, '/private1/disk8/home/oco901/roger/hw.sdw');
insert into starofficetest values (1, '/private1/disk8/home/oco901/roger/January_2000_Sale.sdw');
commit;

create index starofficeindex on starofficetest (thefile) indextype is ctxsys.context
parameters ('datastore ctxsys.file_datastore filter ctxsys.inso_filter');

