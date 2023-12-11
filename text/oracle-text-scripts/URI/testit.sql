set echo on

drop table uri_tab;

create table uri_tab ( id number, url uritype);

insert into uri_tab values  
  (1, httpuritype.createuri('http://www.oracle.com'));
insert into uri_tab values 
  (2, dburitype.createuri('/SCOTT/EMP2/ROW[ENAME="FORD"]'));

select count(*) from uri_tab;

set long 5000

select e.url.getblob() from uri_tab e where id=1;
select e.url.getblob() from uri_tab e where id=2;

connect ctxsys/ctxsys
exec ctx_ddl.drop_preference('myds');
exec ctx_ddl.create_preference('myds', 'multi_column_datastore');
exec ctx_ddl.set_attribute('myds', 'columns', 'base.url.getclob()');

connect scott/tiger
create index myindex on uri_tab (url) indextype is ctxsys.context
parameters ('datastore ctxsys.myds')
/



