connect system/password

--if you want to rerun the script, uncomment next line
--drop user testuser cascade;

create user testuser identified by testuser default tablespace users temporary tablespace temp quota unlimited on users;
grant connect,resource,ctxapp to testuser;

connect testuser/testuser

create table t (c varchar2(2000));

insert into t values ('<sentence>Hello World.</sentence>');

exec ctx_ddl.create_section_group('sec2', 'BASIC_SECTION_GROUP')
exec ctx_ddl.add_special_section('sec2', 'SENTENCE')
exec ctx_ddl.add_special_section('sec2', 'PARAGRAPH')

create index tc on t(c) indextype is ctxsys.context
parameters ('section group sec2 stoplist ctxsys.empty_stoplist');

select token_type, token_text from dr$tc$i;

set long 500000
set pagesize 0
set linesize 132
set trimspool on

spool create_index.sql

select ctx_report.create_index_script('tc') from dual;

spool off
