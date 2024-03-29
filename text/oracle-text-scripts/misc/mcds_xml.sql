drop table mytable;

create table mytable (price number, col1 xmltype, col2 xmltype, col3 xmltype);

insert into mytable values( 200,
   '<color>red</color>',
   '<size>large</size>',
   '<price>200</price>')
;

create or replace function getString (instr xmltype) 
     return varchar2 as
begin
  return instr.getStringVal();
end;
/
show error

exec ctx_ddl.drop_preference  ('mcds')
exec ctx_ddl.create_preference('mcds', 'MULTI_COLUMN_DATASTORE')
exec ctx_ddl.set_attribute    ('mcds', 'COLUMNS', 'getString(col1), getString(col2), getString(col3)')
exec ctx_ddl.set_attribute    ('mcds', 'DELIMITER', 'NEWLINE')

exec ctx_ddl.drop_section_group  ('secgrp')
exec ctx_ddl.create_section_group('secgrp', 'XML_SECTION_GROUP')
exec ctx_ddl.add_field_section   ('secgrp', 'color', 'color', true)
exec ctx_ddl.add_field_section   ('secgrp', 'size',  'size', true)
exec ctx_ddl.add_sdata_section   ('secgrp', 'price', 'price', 'NUMBER')

exec ctx_ddl.drop_section_group  ('secgrp2')
exec ctx_ddl.create_section_group('secgrp2', 'PATH_SECTION_GROUP')


create index mytablei on mytable(col1) 
indextype is ctxsys.context
filter by price
parameters ('datastore mcds section group secgrp2');

select * from mytable where contains(col1, 'red') > 0;

select * from mytable where contains(col1, 'large within size') > 0;

select * from mytable where contains(col1, 'red and sdata(price > 100)') > 0;

select * from mytable where contains(col1, 'red') > 0 and price > 100;

  
