
-- example of using NDATA capabilities from SQL*Plus
-- expect errors on first run as we try to delete stuff not yet created

exec ctx_thes.drop_thesaurus('street_synonyms')

-- load thesaurus file street_synonyms.txt
-- change the line below to include your username/password

host ctxload -user roger/roger -thes -name street_synonyms -file street_synonyms.txt
 
drop table mytab;

create table mytab (
   name varchar2(2000),
   street_addr varchar2(2000)
);

insert into mytab values ('new york hospital', '');
-- insert into mytab values ('Johan Smyth', '120 Somewhere Ln');

insert into mytab values (null, 'Prince William Street');

EXEC ctx_ddl.drop_preference('example_ds')
BEGIN
  ctx_ddl.create_preference('example_ds', 'MULTI_COLUMN_DATASTORE');
  ctx_ddl.set_attribute('example_ds', 'COLUMNS', 'name, street_addr');
END;
/

EXEC ctx_ddl.drop_section_group('example_sg');
BEGIN
  ctx_ddl.create_section_group('example_sg', 'BASIC_SECTION_GROUP');
  ctx_ddl.add_ndata_section('example_sg', 'name', 'name');
  ctx_ddl.add_ndata_section('example_sg', 'street_addr', 'street_addr');
END;
/

EXEC ctx_ddl.drop_preference('example_wl');
BEGIN
  ctx_ddl.create_preference('example_wl', 'BASIC_WORDLIST');
  ctx_ddl.set_attribute('example_wl', 'NDATA_ALTERNATE_SPELLING', 'FALSE');
  ctx_ddl.set_attribute('example_wl', 'NDATA_THESAURUS', 'street_synonyms');
  ctx_ddl.set_attribute('example_wl', 'NDATA_BASE_LETTER', 'TRUE');
END;
/

create index myind on mytab (name)  
INDEXTYPE IS ctxsys.context
parameters ('datastore example_ds section group example_sg wordlist example_wl');

select * from mytab where contains (name, 'NDATA(name, john smith)') > 0;

select * from mytab where contains (name, 'NDATA(name, john smith) AND NDATA(street_addr, som where ln)') > 0;

select * from mytab where contains (name, 'NDATA(street_addr, Billy Road)') > 0;

