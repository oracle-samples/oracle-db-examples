drop table people;
create table people (lastname varchar2(60));

insert all
  into people values ('<name>Eichinger</name>')
  into people values ('<name>Mairhofer</name>')
  into people values ('<name>Mairhofer</name>')
  into people values ('<name>Mairhofer</name>')
  into people values ('<name>Maier</name>')
  into people values ('<name>Eichinger</name>')
  into people values ('<name>Maier</name>')
  into people values ('<name>Maier</name>')
  into people values ('<name>Meisenberger</name>')
  into people values ('<name>Eichinger</name>')
  into people values ('<name>Meier</name>')
  into people values ('<name>Meier-Weber</name>')
  into people values ('<name>Maier</name>')
  into people values ('<name>Maierhofer</name>')
  into people values ('<name>Maier</name>')
  into people values ('<name>Maier</name>')
  into people values ('<name>Eichinger</name>')
  into people values ('<name>Mairhofer</name>')
  into people values ('<name>Maierhofer</name>')
  into people values ('<name>Maier</name>')
  into people values ('<name>Meyer</name>')
  into people values ('<name>Meyer</name>')
  into people values ('<name>Maierhofer</name>')
  into people values ('<name>Eichinger</name>')
  into people values ('<name>Eichinger</name>')
  into people values ('<name>Eichinger</name>')
  into people values ('<name>Maier</name>')
  into people values ('<name>Maier</name>')
  into people values ('<name>Mairhofer</name>')
  into people values ('<name>aier</name>')
  select * from dual
/

exec ctx_ddl.drop_section_group  ('mysections')
exec ctx_ddl.create_section_group('mysections', 'BASIC_SECTION_GROUP')
exec ctx_ddl.add_ndata_section   ('mysections', 'name', 'name')

create index peopleindex on people(lastname) indextype is ctxsys.context
parameters('section group mysections')
/

select score(1), lastname from people where contains(lastname, 'ndata(name, meier)', 1) > 0
/

