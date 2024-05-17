connect sys/password as sysdba

alter session set current_schema = ROGER;

drop table mytable99;

create table mytable99 (text varchar2(2000));

insert into mytable99 values ('the cat_sat on the mat');

exec ctx_ddl.drop_preference   ('mypref')
exec ctx_ddl.create_preference ('mypref', 'BASIC_LEXER')
exec ctx_ddl.set_attribute     ('mypref', 'PRINTJOINS', '_')

create index myindex99 on mytable99(text) indextype is ctxsys.context parameters ('lexer mypref');

exec ctx_ddl.sync_index('myindex99')
exec ctx_ddl.optimize_index('myindex99', 'FULL')

exec ctx_ddl.create_shadow_index('roger.myindex99', 'replace NOPOPULATE');
