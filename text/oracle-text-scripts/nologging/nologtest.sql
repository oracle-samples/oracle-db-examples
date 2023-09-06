-- check the difference in performance between a normal and a NOLOGGING
-- tablespace to hold text indexes

set echo on

connect system/password

drop user testuser cascade;

--drop tablespace testtab including contents and datafiles;
--drop tablespace testind including contents and datafiles;

--create tablespace testtab datafile 'testtab1.dbf' size 1g autoextend on;
--create tablespace testind datafile 'testind1.dbf' size 1g autoextend on nologging;

create user testuser identified by testuser default tablespace testtab temporary tablespace temp quota unlimited on testtab quota unlimited on testind;

grant connect,resource,ctxapp to testuser;

connect testuser/testuser

create table t(c varchar2(2000));

insert into t values ('The quick brown <animal>fox</animal> is <age>20</age> today');

exec ctx_ddl.create_section_group('sg', 'html_section_group')
exec ctx_ddl.add_sdata_section   ('sg', 'animal', 'animal')
exec ctx_ddl.add_sdata_section   ('sg', 'age', 'age', 'NUMBER')

exec ctx_ddl.create_preference('st', 'BASIC_STORAGE')
exec ctx_ddl.set_attribute('st', 'S_TABLE_CLAUSE', 'TABLESPACE TESTTAB')
exec ctx_ddl.set_attribute('st', 'I_TABLE_CLAUSE', 'TABLESPACE TESTTAB')

create index i on t(c) indextype is ctxsys.context
parameters ('section group sg storage st');

begin
  for i in 1 .. 1000 loop
     insert into t values ( 'foo' || i || ' <age>' || i  || '</age>' );
     commit;
     ctx_ddl.sync_index('i');
  end loop;
end;
/

exec ctx_ddl.sync_index('i')

select sdata_id, count(*) from dr$i$s group by sdata_id;

exec ctx_ddl.optimize_index('i', 'FAST')

select sdata_id, count(*) from dr$i$s group by sdata_id;

exec ctx_ddl.optimize_index('i', 'FULL')

select sdata_id, count(*) from dr$i$s group by sdata_id;
