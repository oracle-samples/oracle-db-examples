connect / as sysdba
drop user spmu cascade;
create user spmu identified by spmu;
grant connect to spmu;
grant select on plan_table to spmu;
grant select on dba_sql_plan_baselines to spmu;
grant ADMINISTER SQL MANAGEMENT OBJECT to spmu;
alter user spmu default tablespace sysaux;
alter user spmu quota unlimited on sysaux;
connect spmu/spmu
