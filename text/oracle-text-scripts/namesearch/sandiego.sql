drop table tab1 purge;
create table tab1(col1 varchar2(50));

--should not come back

insert into tab1 values('Where is Diego CA');
insert into tab1 values('San fricken doody CA');

--should come back

insert into tab1 values('Sam fricken doody Diego CA');
insert into tab1 values('Sam fricken doody Doogie CA');
insert into tab1 values('San fricken doody Diego CA');
insert into tab1 values('SanDiego CA');
insert into tab1 values('SamDoogie CA');
commit;

exec ctx_ddl.drop_preference('myds')
exec ctx_ddl.create_preference('myds', 'MULTI_COLUMN_DATASTORE')
exec ctx_ddl.set_attribute('myds', 'COLUMNS', 'col1')
 
exec ctx_ddl.drop_section_group('mysec')
exec ctx_ddl.create_section_group('mysec', 'BASIC_SECTION_GROUP')
exec ctx_ddl.add_ndata_section('mysec', 'COL1', 'COL1')

create index tab1_idx on tab1(col1) indextype is ctxsys.context
parameters('datastore myds section group mysec')
/

select score(1), col1 from tab1 where contains(col1, 'ndata(col1, San Diego)', 1) > 0 
order by score(1) desc;



 
