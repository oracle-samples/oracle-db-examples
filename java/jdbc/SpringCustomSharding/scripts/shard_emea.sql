-- To be executed on EMEA CDB

set echo on

alter system set open_links=30 scope=spfile;
alter system set open_links_per_instance=30 scope=spfile;
alter system set standby_file_management=auto scope=both;

alter user gsmrootuser account unlock;
alter user gsmrootuser identified by CHANGE_ME;
grant SYSDG, SYSBACKUP to gsmrootuser;

grant read,write on directory DATA_PUMP_DIR to gsmadmin_internal;
grant read,write on directory DATA_PUMP_DIR to gsmuser;
alter user gsmuser account unlock;
alter user gsmuser identified by CHANGE_ME;
grant SYSDG, SYSBACKUP to gsmuser;

alter database flashback on;

alter system set global_names=FALSE scope=both;
alter system set dg_broker_start=true scope=both;

alter pluggable database PEMEA open instances=all;
alter pluggable database PEMEA save state instances=all;

alter session set container=PEMEA;
grant SYSDG, SYSBACKUP to gsmuser;
grant read,write on directory DATA_PUMP_DIR to gsmadmin_internal;
grant read,write on directory DATA_PUMP_DIR to gsmuser;
alter session set container=cdb$root;

-- Restart the shard for the configurations to take effect:
-- shutdown immediate;
-- startup;

alter session set container=PEMEA;

set serveroutput on
exec DBMS_GSM_FIX.VALIDATESHARD;

alter session set container=cdb$root;
