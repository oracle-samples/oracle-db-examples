set echo on

drop index lib_index;
drop table library_stock;
exec ctx_ddl.drop_section_group('mysg');

create table library_stock 
  (id number primary key, 
   book_info clob);

insert into library_stock values (1, '<stocklevel>1</stocklevel>');
insert into library_stock values (2, '<stocklevel>10</stocklevel>');
insert into library_stock values (3, '<stocklevel>2</stocklevel>');
insert into library_stock values (4, '<stocklevel>15</stocklevel>');
insert into library_stock values (5, '<stocklevel>17</stocklevel>');
insert into library_stock values (6, '<stocklevel>6</stocklevel>');
insert into library_stock values (7, '<stocklevel>172</stocklevel>');
insert into library_stock values (8, '<stocklevel>12</stocklevel>');
insert into library_stock values (9, '<stocklevel>14</stocklevel>');
insert into library_stock values (10, '<stocklevel>88</stocklevel>');
insert into library_stock values (11, '<stocklevel>6</stocklevel>');
insert into library_stock values (12, '<stocklevel>33</stocklevel>');
insert into library_stock values (13, '<stocklevel>44</stocklevel>');
insert into library_stock values (14, '<stocklevel>10</stocklevel>');
insert into library_stock values (15, '<stocklevel>11</stocklevel>');
insert into library_stock values (16, '<stocklevel>11</stocklevel>');
insert into library_stock values (17, '<stocklevel>1</stocklevel>');
insert into library_stock values (18, '<stocklevel>3</stocklevel>');
insert into library_stock values (19, '<stocklevel>1</stocklevel>');
insert into library_stock values (20, '<stocklevel>1</stocklevel>');
insert into library_stock values (21, '<stocklevel>12</stocklevel>');
insert into library_stock values (22, '<stocklevel>99</stocklevel>');
insert into library_stock values (23, '<stocklevel>26</stocklevel>');
insert into library_stock values (24, '<stocklevel>2</stocklevel>');
insert into library_stock values (25, '<stocklevel>4</stocklevel>');
insert into library_stock values (26, '<stocklevel>19</stocklevel>');
insert into library_stock values (27, '<stocklevel>23</stocklevel>');
insert into library_stock values (28, '<stocklevel>19</stocklevel>');
insert into library_stock values (29, '<stocklevel>4</stocklevel>');

  '<title>The World According to Garp</title>
   <author>John Irving</author>
   <status>In, Stock</status>
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

select score(1), book_info from library_stock 
where contains (book_info, 
'owen and mdata(status, In ''Stock)*10*10',1) > 0;


