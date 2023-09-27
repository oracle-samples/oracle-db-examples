drop table my_table
/
create table my_table( city varchar2(30), name varchar2(30), ssid number )
/
insert into my_table values( 'New York', 'James', 1);
insert into my_table values( 'New York', 'Allen', 2);
insert into my_table values( 'Washington', 'Obama', 3);
insert into my_table values( 'New York', 'James', 4);

exec ctx_ddl.drop_preference  ( 'my_ds' )
exec ctx_ddl.create_preference( 'my_ds', 'MULTI_COLUMN_DATASTORE' )
exec ctx_ddl.set_attribute    ( 'my_ds', 'COLUMNS', 'city, name' )

exec ctx_ddl.drop_preference  ( 'my_wl' )
exec ctx_ddl.create_preference( 'my_wl', 'BASIC_WORDLIST' )
exec ctx_ddl.set_attribute    ( 'my_wl', 'SUBSTRING_INDEX', 'true' )

exec ctx_ddl.drop_section_group  ( 'my_sg' )
exec ctx_ddl.create_section_group( 'my_sg', 'BASIC_SECTION_GROUP' )
exec ctx_ddl.add_mdata_section   ( 'my_sg', 'city', 'city' )

exec ctx_output.start_log( 'my_index.log' )

create index my_index on my_table( name )
indextype is ctxsys.context
parameters( 'datastore my_ds wordlist my_wl section group my_sg memory 500M' )
parallel 8
/

exec ctx_output.end_log

select * from my_table where contains( name, '%bam% and mdata(city, Washington)' ) > 0
/
select * from my_table where contains( name, '%J% and mdata(city, New York)' ) > 0
/


