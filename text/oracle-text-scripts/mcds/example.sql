-- simple example of multi_column_datastore

set echo on

drop table locs;

create table locs (
  id number primary key,
  serial_number varchar2(20),
  sale_unit_name varchar2(20),
  company_name varchar2(20) 
);

insert into locs values (1, 'dog', 'cat', 'abc');
insert into locs values (2, 'cat', 'abc', 'dog');
insert into locs values (3, 'abc', 'cat', 'dog');
insert into locs values (4, 'cat', 'dog', 'rat');

exec ctx_ddl.drop_preference   ('myds')
exec ctx_ddl.create_preference ('myds', 'MULTI_COLUMN_DATASTORE')
exec ctx_ddl.set_attribute     ('myds', 'COLUMNS', 'serial_number, sale_unit_name, company_name')

-- OPTIONAL : only if you want to search withing specific columns

exec ctx_ddl.drop_section_group   ('mysec')
exec ctx_ddl.create_section_group ('mysec', 'BASIC_SECTION_GROUP')
exec ctx_ddl.add_field_section    ('mysec', 'serial_number',  'serial_number',  true)
exec ctx_ddl.add_field_section    ('mysec', 'sale_unit_name', 'sale_unit_name', true)
exec ctx_ddl.add_field_section    ('mysec', 'company_name',   'company_name',   true)

-- we have to choose one column to actually create the index on. This could be a new column
-- such as dummy varchar2(1) which just contains the value 'X', or we can use a real column
-- as we do here:

create index locs_index on locs(serial_number)
indextype is ctxsys.context
parameters ('datastore myds section group mysec sync (on commit)');

-- trigger should update indexed column if any column used in index changes
-- it is sufficient to update value to itself 
-- for 12.1 see https://blogs.oracle.com/searchtech/entry/datastore_triggers_in_12c
 
create or replace trigger customer_update_trg
before update of serial_number, sale_unit_name, company_name on locs
  for each row
begin
  :new.serial_number := :new.serial_number;
end; 
/
show errors

-- search any column

select * from locs where contains (serial_number, 'AB%') > 0;

-- column specific search

select * from locs where contains (serial_number, 'AB% WITHIN company_name') > 0;

-- check updates work

update locs set company_name = 'ABC' where id = 4;

commit;

select * from locs where contains (serial_number, 'AB% WITHIN company_name') > 0;
