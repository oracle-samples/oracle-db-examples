drop table mytable;

create table mytable (text varchar2(2000));

insert into mytable values ('oracle');
exec ctx_ddl.drop_preference('mywordlist')
exec ctx_ddl.create_preference('mywordlist', 'basic_wordlist')
exec ctx_ddl.set_attribute('mywordlist', 'wildcard_index', 'true')

create index myindex on mytable (text) indextype is ctxsys.context
parameters ('wordlist mywordlist');

set echo on

select table_name from user_tables where table_name like 'DR$MYINDEX%';
