-- example of multi column datastore to index two columns in one index

drop table companies;

create table companies (
 foo   number,
 score number,
 long_description varchar2(2000),
 short_description varchar2(2000)
);

insert into companies values ('a boutique hotel', 'great hotels');

exec ctx_ddl.drop_preference('mymcds')
exec ctx_ddl.create_preference('mymcds', 'MULTI_COLUMN_DATASTORE')
exec ctx_ddl.set_attribute ('mymcds', 'COLUMNS', 'short_description,long_description')

exec ctx_ddl.drop_section_group('mysecgrp')
exec ctx_ddl.create_section_group('mysecgrp', 'BASIC_SECTION_GROUP')
exec ctx_ddl.add_field_section('mysecgrp', 'short_description', 'short_description', true)
exec ctx_ddl.add_field_section('mysecgrp', 'long_description', 'long_description', true)

create index myindex on companies(short_description)
indextype is ctxsys.context
filter by score
parameters ('datastore mymcds section group mysecgrp');

select * from companies where 
contains (short_description, 'hotel or hotels') > 0;


select * from companies where 
contains (short_description, 'hotels WITHIN short_description') > 0;

