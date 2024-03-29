set echo on

connect system/password

drop user testuser cascade;

drop tablespace testtab including contents and datafiles;
create tablespace testtab datafile 'testtab1.dbf' size 1g autoextend on;

create user testuser identified by testuser default tablespace testtab temporary tablespace temp quota unlimited on testtab quota unlimited on testind;

grant connect,resource,ctxapp to testuser;

connect testuser/testuser

create table t(c varchar2(2000));

insert into t values ('The quick brown fox');

exec ctx_ddl.create_section_group('sg', 'html_section_group')

begin
   for i in 1 .. 33 loop
     ctx_ddl.add_sdata_section('sg', 'sdat'||i, 'sdat'||i);
   end loop;
end;
/

exec ctx_ddl.create_preference('st', 'BASIC_STORAGE')

create index i on t(c) indextype is ctxsys.context
parameters ('section group sg');

exec ctx_ddl.sync_index('i')

select sdata_id, count(*) from dr$i$s group by sdata_id;

exec ctx_ddl.optimize_index('i', 'FAST')

select sdata_id, count(*) from dr$i$s group by sdata_id;

exec ctx_ddl.optimize_index('i', 'FULL')

select sdata_id, count(*) from dr$i$s group by sdata_id;

variable rpt clob

exec dbms_lob.createtemporary(:rpt, true)

exec ctx_report.index_stats('i', :rpt)
