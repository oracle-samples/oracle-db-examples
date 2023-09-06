drop table table1;
create table table1 (doc clob);

insert into table1 values ('<ABC T1="N"> <T2 CODE="BEA"/> </ABC>');

exec ctx_ddl.drop_section_group('MyGroup')

exec ctx_ddl.create_section_group('MyGroup','AUTO_SECTION_GROUP')
--exec ctx_ddl.add_zone_section('MyGroup', 'ABC', 'ABC')
--exec ctx_ddl.add_attr_section('MyGroup', 'T2@CODE', 'T2@CODE')

create index index1 on table1 (doc) indextype is ctxsys.context
parameters ('section group MyGroup');



