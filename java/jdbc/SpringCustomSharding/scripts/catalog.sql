-- To be executed on CATALOG CDB

alter system set open_links=30 scope=spfile;
alter system set open_links_per_instance=30 scope=spfile;
alter system set standby_file_management=auto scope=both;
alter system set global_names=FALSE scope=both;
alter system set db_files=1024 scope=spfile;
alter database flashback on;
archive log list
alter user gsmcatuser account unlock;
alter system set event='10798 trace name context forever, level 1' scope=spfile;
alter system set events 'immediate trace name GWM_TRACE level 1';

show pdbs
set serveroutput on
exec DBMS_GSM_FIX.VALIDATESHARD;

alter pluggable database PCATALOG open instances=all;
alter pluggable database PCATALOG save state instances=all;

alter session set container=PCATALOG;
grant SYSDG, SYSBACKUP to gsmuser;
alter session set container=cdb$root;

-- Restart the catalog for the configurations to take effect:
-- shutdown immediate;
-- startup;
