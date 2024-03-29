set echo on

drop index lib_index;
drop table library_stock;
exec ctx_ddl.drop_section_group('mysg');

create table library_stock 
  (id number primary key, 
   book_info clob);

insert into library_stock values (1, 
  '<title>A Prayer for Owen Meany</title>
   <author>John Irving</author>
   <status>In Stock)</status>
   <stocklevel>1</stocklevel>');

insert into library_stock values (2,
  '<title>The World According to Garp</title>
   <author>John Irving</author>
   <status>  In Stock)</status>
   <stocklevel>12</stocklevel>');

insert into library_stock values (3,
  '<title>The Hotel New Hampshire</title>
   <author>John Irving</author>
   <status>Out of Stock</status>
   <stocklevel>0</stocklevel>');

exec ctx_ddl.create_section_group(group_name=>'mysg', group_type=>'xml_section_group');

exec ctx_ddl.add_field_section(group_name=>'mysg', section_name=>'title', tag=>'title', visible=>TRUE);
exec ctx_ddl.add_field_section(group_name=>'mysg', section_name=>'author', tag=>'author', visible=>TRUE);

exec ctx_ddl.add_mdata_section(group_name=>'mysg', section_name=>'status', tag=>'status');
exec ctx_ddl.add_mdata_section(group_name=>'mysg', section_name=>'stocklevel', tag=>'stocklevel');

create index lib_index on library_stock (book_info)
indextype is ctxsys.context 
parameters ('section group mysg');

select err_text from ctx_user_index_errors where err_index_name = 'LIB_INDEX';

set long 10000

column token_text format a30
select token_text, token_type, token_first, token_last, token_count
from dr$lib_index$i
where token_type >= 400 or token_type <= -400;

select book_info from library_stock 
where contains (book_info, 
'irving within author and mdata(status, In Stock))') > 0;


