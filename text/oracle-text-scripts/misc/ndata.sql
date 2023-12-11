drop table testcase;

create table testcase (text varchar2(2000));

insert into testcase values ('<nd>walmart</nd>');
insert into testcase values ('<nd>wal mart</nd>');

exec ctx_ddl.drop_section_group('tcsg')
exec ctx_ddl.create_section_group('tcsg', 'xml_section_group')
exec ctx_ddl.add_ndata_section('tcsg', 'nd', 'nd')

create index testcase_index on testcase(text) 
indextype is ctxsys.context
parameters ('section group tcsg')
/

select * from testcase where contains (text, 'ndata(nd, wal mart)') > 0;
select * from testcase where contains (text, 'ndata(nd, wal-mart)') > 0;
select * from testcase where contains (text, 'ndata(nd, wal*mart)') > 0;
select * from testcase where contains (text, 'ndata(nd, walmart)') > 0;


