alter session set events '30579 trace name context forever, level 4'; 

exec ctx_ddl.drop_section_group('namegroup1')

begin
  ctx_ddl.create_section_group('namegroup1', 'BASIC_SECTION_GROUP');
  ctx_ddl.add_ndata_section('namegroup1','firstname','firstname');
  ctx_ddl.add_ndata_section('namegroup1','surname','surname');
end;
/

exec ctx_ddl.drop_preference('ndata_pref')

begin
  ctx_ddl.create_preference('NDATA_PREF', 'BASIC_WORDLIST'); 
  ctx_ddl.set_attribute('NDATA_PREF', 'NDATA_ALTERNATE_SPELLING', 'FALSE');
  ctx_ddl.set_attribute('NDATA_PREF', 'NDATA_BASE_LETTER', 'TRUE');
  ctx_ddl.set_attribute('NDATA_PREF', 'NDATA_THESAURUS', 'NICKNAMES');
end;
/

drop table people;

create table people(firstname varchar2(80),surname varchar2(80));
insert into people values('John','Smith');
insert into people values('jean','smythe');
insert into people values('jon','smithe');

exec ctx_ddl.drop_preference('mynameds')
exec ctx_ddl.create_preference('mynameds', 'MULTI_COLUMN_DATASTORE');
exec ctx_ddl.set_attribute('mynameds', 'columns', 'firstname,surname');

create index people_index on people(surname) indextype is ctxsys.context
parameters ('datastore mynameds section group namegroup1 wordlist ndata_pref')
/

select * from people where contains (surname, 'ndata(surname, smith)') > 0;
