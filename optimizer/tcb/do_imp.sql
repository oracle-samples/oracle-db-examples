connect tcb_dba/tcb_dba

whenever sqlerror exit
--
-- Drop preexisting SPM staging table
--
begin
  execute immediate 'drop table my_spm_staging_tab';
exception
  when others then null;
end;
/

create or replace directory TCB_EXPORT_LOCATION as '/tmp/TCB';

set serveroutput on
--
-- Import the test case
--
begin
-- Make sure directory name is upper case
  dbms_sqldiag.import_sql_testcase (directory=>'TCB_EXPORT_LOCATION'
                                   ,filename=>'mytestcasemain.xml'
                                   ,preserveSchemaMapping=>true);
end;
/
--
-- Due to TCB bug, we have to import the SQL plan baselines
-- manually. 
--
declare
  h1 number;
  job_state varchar2(100);
  sts ku$_Status;
begin
   h1 := DBMS_DATAPUMP.OPEN('IMPORT','FULL');
   DBMS_DATAPUMP.ADD_FILE(h1,'spm_pack.dmp','TCB_EXPORT_LOCATION');
   DBMS_DATAPUMP.SET_PARAMETER(h1,'TABLE_EXISTS_ACTION','REPLACE');
   DBMS_DATAPUMP.START_JOB(h1);
   job_state := 'UNDEFINED';
   while (job_state != 'COMPLETED') and (job_state != 'STOPPED')
   loop
     dbms_datapump.get_status(h1,
           dbms_datapump.ku$_status_job_error +
           dbms_datapump.ku$_status_job_status +
           dbms_datapump.ku$_status_wip,-1,job_state,sts);
   end loop;
end;
/ 

prompt SPM staging table...
select count(*) from my_spm_staging_tab;
--
-- Unpack the SQL plan baselines
--
set serveroutput on
declare
  n number;
begin
  n := dbms_spm.unpack_stgtab_baseline('my_spm_staging_tab');
  dbms_output.put_line('Imported '||n||' SQL plan baselines');
end;
/
set serveroutput off

