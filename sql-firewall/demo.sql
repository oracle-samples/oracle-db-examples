set echo on
-----------------------------------
Rem Setup for the demo:
Rem Create users including schema accounts and administrators for managing SQL Firewall
Rem the different database artifacts required for the demo

-----------------------------------
accept syspwd char prompt 'Enter sys password: ' 
accept dba_user char prompt 'Enter a DBA username who will be able to administer SQL Firewall and Audit: '
accept userpwd char prompt 'Enter random password that will be assigned to users created in the script: '

conn sys/&syspwd as sysdba
noaudit policy ORA_ALL_TOPLEVEL_ACTIONS;


BEGIN
 IF
   NOT DBMS_AUDIT_MGMT.IS_CLEANUP_INITIALIZED(DBMS_AUDIT_MGMT.AUDIT_TRAIL_ALL)
 THEN
  DBMS_AUDIT_MGMT.INIT_CLEANUP(
      audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_ALL,
      default_cleanup_interval => 24 /* hours */);
 END IF;
END;
/

exec DBMS_AUDIT_MGMT.CLEAN_AUDIT_TRAIL(audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_ALL, use_last_arch_timestamp=>FALSE);


-- &dba_user is administrator user for SQL Firewall and Audit
create user &dba_user identified by &userpwd;
grant create session, sql_firewall_admin, audit_admin to &dba_user;

-- create the application users
create user app_data identified by &userpwd;
create user app_runtime identified by &userpwd;

grant create session to app_runtime;
grant create session, create table, unlimited tablespace to app_data;
grant create procedure, create public synonym, create view to app_data;

commit;

conn app_data/&userpwd
-- create tables
create table CUSTOMER_INFO (
  cid              VARCHAR2(128),
  name             VARCHAR2(128),
  address          VARCHAR2(128),
  credit_card      VARCHAR2(128)
);

create table CUSTOMER_ACCT (
  cid              VARCHAR2(128),
  balance          NUMBER,
  acct_type        VARCHAR2(128)
);

insert into CUSTOMER_INFO (cid, name, address, credit_card) values ('1', 'Bob', '400 Oracle Parkway', '******8118');
insert into CUSTOMER_INFO (cid, name, address, credit_card) values ('2', 'Jack', '500 Oracle Parkway', '******7641');
insert into CUSTOMER_INFO (cid, name, address, credit_card) values ('3', 'Joe', '600 Oracle Parkway', '******3720');
insert into CUSTOMER_INFO (cid, name, address, credit_card) values ('4', 'Tom', '100 Oracle Parkway', '******2873');

insert into CUSTOMER_ACCT (cid, balance, acct_type) values ('1', 400, 'online');
insert into CUSTOMER_ACCT (cid, balance, acct_type) values ('1', 500, 'in store');
insert into CUSTOMER_ACCT (cid, balance, acct_type) values ('2', 200, 'online');
insert into CUSTOMER_ACCT (cid, balance, acct_type) values ('2', 700, 'in store');
insert into CUSTOMER_ACCT (cid, balance, acct_type) values ('3', 500, 'online');
insert into CUSTOMER_ACCT (cid, balance, acct_type) values ('3', 900, 'in store');
insert into CUSTOMER_ACCT (cid, balance, acct_type) values ('4', 1000, 'online');
insert into CUSTOMER_ACCT (cid, balance, acct_type) values ('4', 1300, 'in store');

commit;

create or replace view app_data.customer_balances as
select name, balance
from app_data.customer_info info,
(select cid, sum(balance) balance from app_data.customer_acct group by cid) acct
where info.cid = acct.cid; 

create or replace procedure update_customer_addr (cid varchar2, address varchar2) is
  sqlstmt varchar2(1000);
begin
  sqlstmt := 'BEGIN UPDATE customer_info SET address = ';
  sqlstmt := sqlstmt || '''' || address || ''' WHERE cid = ''' || cid || '''; COMMIT; END;';

  DBMS_OUTPUT.PUT_LINE('Query: ' || sqlstmt);
  execute immediate sqlstmt;
end;
/

CREATE OR REPLACE PROCEDURE get_balance ( 
  cid        IN  VARCHAR2, 
  acct_type  IN  VARCHAR2
)
IS
  rec   VARCHAR2(4000);
  query VARCHAR2(4000); 
BEGIN 
  
  query := 'SELECT balance FROM customer_acct WHERE cid=''' 
           || cid
           || ''' AND acct_type='''  
           || acct_type
           || ''''; 
  DBMS_OUTPUT.PUT_LINE('Query: ' || query); 
  EXECUTE IMMEDIATE query INTO rec;
  DBMS_OUTPUT.PUT_LINE('Account balance: ' || rec ); 
END; 
/

grant execute on get_balance to app_runtime;
grant execute on update_customer_addr to app_runtime;
grant select,insert,update,delete on customer_info to app_runtime;
grant select,insert,update,delete on customer_acct to app_runtime;
grant read on app_data.customer_balances to app_runtime;

create public synonym get_balance for app_data.get_balance;
create public synonym update_customer_addr for app_data.update_customer_addr;
create public synonym customer_balances for app_data.customer_balances;

-----------------------------------
Rem Enable SQL Firewall 
-----------------------------------

pause;

conn &dba_user/&userpwd
exec dbms_sql_firewall.enable;
select status from dba_sql_firewall_status;
--select * from dba_sql_firewall_status;
-----------------------------------
Rem Create and start the capture 
-----------------------------------

pause;

conn &dba_user/&userpwd
exec dbms_sql_firewall.create_capture('APP_RUNTIME');
select username, top_level_only, status from dba_sql_firewall_captures where username='APP_RUNTIME';
--select * from dba_sql_firewall_captures where username='APP_RUNTIME';
-----------------------------------
Rem Run the application workload SQL from known trusted database connection paths
-----------------------------------

pause;

conn app_runtime/&userpwd

execute update_customer_addr('1', '335 market street');
execute get_balance('2', 'online');

select name, address from app_data.customer_info where cid = '5';

insert into app_data.customer_info values ('5', 'Mary', '200 Oracle PKWY', '*******1020');
select name, address from app_data.customer_info where cid = '5';

delete from app_data.customer_info where cid = '5';
select name, address from app_data.customer_info where cid = '5';

select name, balance from app_data.customer_balances;

select max(balance) from customer_balances;

select count(*) from app_data.customer_info info
where info.cid in (select cid from app_data.customer_acct);

commit;

-----------------------------------
Rem Stop capture and check capture log
-----------------------------------

pause;

conn &dba_user/&userpwd
exec dbms_sql_firewall.stop_capture('APP_RUNTIME');

Rem View the session logs

pause;

select username, ip_address, client_program, os_user
from dba_sql_firewall_session_logs
where username = 'APP_RUNTIME' order by login_time;
--select * from dba_sql_firewall_session_logs
Rem View the capture logs

pause;

select username, current_user, top_level, command_type, sql_text,
accessed_objects, client_program, os_user, ip_address
from dba_sql_firewall_capture_logs
where username = 'APP_RUNTIME' order by ip_address, command_type, sql_signature;
--select * from dba_sql_firewall_capture_logs
Rem Capture logs: session unique

pause;

select count(*)
from dba_sql_firewall_capture_logs
group by (session_id, current_user, top_level, sql_text, accessed_objects);

-----------------------------------
Rem Generate allow list
-----------------------------------

pause;

conn &dba_user/&userpwd
exec dbms_sql_firewall.generate_allow_list('APP_RUNTIME');

Rem view allow list

pause;

select username, status, top_level_only from dba_sql_firewall_allow_lists where username='APP_RUNTIME';
--select * from dba_sql_firewall_allow_lists where username='APP_RUNTIME';
Rem view allowed SQLs

pause;

select username, current_user, top_level, sql_text, accessed_objects
from dba_sql_firewall_allowed_sql
where username='APP_RUNTIME' order by sql_text, current_user, top_level;
--select * from dba_sql_firewall_allowed_sql
Rem the count matches the count of distinct events we captured

pause;

select count(*) from 
(select distinct username, current_user, top_level, sql_text, accessed_objects
from dba_sql_firewall_capture_logs
where username='APP_RUNTIME');

Rem view allowed contexts

pause;

select username, ip_address from sys.dba_sql_firewall_allowed_ip_addr where username='APP_RUNTIME';
select username, os_user from sys.dba_sql_firewall_allowed_os_user where username='APP_RUNTIME';
select username, os_program from sys.dba_sql_firewall_allowed_os_prog where username='APP_RUNTIME';

Rem view mandatory audit records for admin APIs

pause;

select audit_type, dbusername, current_user, action_name, fw_action_name, fw_return_code,
sql_text, unified_audit_policies from unified_audit_trail
where ACTION_NAME = 'FW ADMIN ACTION'
order by event_timestamp;

----------------------------------------
Rem Set up audit policy
----------------------------------------

pause;

conn &dba_user/&userpwd
create audit policy APPLICATION_AUDIT_POLICY actions component = SQL_Firewall ALL on app_runtime;
audit policy APPLICATION_AUDIT_POLICY;
exec DBMS_AUDIT_MGMT.CLEAN_AUDIT_TRAIL(audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_ALL, use_last_arch_timestamp=>FALSE);

-----------------------------------
Rem Enable allow list
-----------------------------------

pause;

conn &dba_user/&userpwd
exec dbms_sql_firewall.enable_allow_list('APP_RUNTIME');

select username, status, top_level_only, enforce, block from dba_sql_firewall_allow_lists where username='APP_RUNTIME';

-----------------------------------
Rem Run the exact same workload (matched, no violation log)
-----------------------------------

pause;


conn app_runtime/&userpwd

execute update_customer_addr('1', '335 market street');
execute get_balance('2', 'online');

select name, address from app_data.customer_info where cid = '5';

insert into app_data.customer_info values ('5', 'Mary', '200 Oracle PKWY', '*******1020');
select name, address from app_data.customer_info where cid = '5';

delete from app_data.customer_info where cid = '5';
select name, address from app_data.customer_info where cid = '5';

select name, balance from app_data.customer_balances;

select max(balance) from customer_balances;

select count(*) from app_data.customer_info info
where info.cid in (select cid from app_data.customer_acct);

commit;
 
-----------------------------------
Rem Issue some unknown statements; connect with unknown context
Rem All will go through
Rem Unmatched SQL and context will have violation log
-----------------------------------


Rem unknown traffic not in original whitelist
pause;
conn app_runtime/&userpwd
-- unknown traffic: not in application workload.
select * from app_data.customer_info order by cid;



-----------------------------------
Rem Check violation logs and audit records
-----------------------------------

pause;

conn &dba_user/&userpwd
exec dbms_sql_firewall.flush_logs;

Rem Check violation logs
pause;

select username, cause, firewall_action, current_user, top_level,
command_type, sql_text, accessed_objects,
ip_address, client_program, os_user
from dba_sql_firewall_violations where username='APP_RUNTIME' order by occurred_at;

Rem Check audit records
pause;

select audit_type, dbusername, current_user, fw_action_name, fw_return_code,
sql_text, unified_audit_policies
from unified_audit_trail
where UNIFIED_AUDIT_POLICIES like '%APPLICATION_AUDIT_POLICY%'
order by event_timestamp;

-----------------------------------
Rem Purge violation logs and audit records
-----------------------------------

pause;

conn &dba_user/&userpwd
exec dbms_sql_firewall.purge_log('APP_RUNTIME', NULL, dbms_sql_firewall.VIOLATION_LOG);
exec DBMS_AUDIT_MGMT.CLEAN_AUDIT_TRAIL(audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_ALL, use_last_arch_timestamp=>FALSE);

-----------------------------------
Rem update the allow list enforcement to block mode
-----------------------------------

pause;

conn &dba_user/&userpwd
exec dbms_sql_firewall.update_allow_list_enforcement('APP_RUNTIME', block=>TRUE);
select username, status, top_level_only, enforce, block
from dba_sql_firewall_allow_lists where username='APP_RUNTIME';

-----------------------------------
Rem Issue some unknown statements; connect with unknown context
Rem The Unmatched SQLs and connection with unknown context
Rem will be blocked and have violation logs
-----------------------------------


Rem unknown traffic not in original whitelist
pause;
conn app_runtime/&userpwd
-- unknown traffic: not in application workload.
select * from app_data.customer_info order by cid;



-----------------------------------
Rem Check violation logs and audit records
-----------------------------------

pause;

conn &dba_user/&userpwd
exec dbms_sql_firewall.flush_logs;

Rem Check violation logs
pause;

select username, cause, firewall_action, current_user, top_level,
command_type, sql_text, accessed_objects,
ip_address, client_program, os_user
from dba_sql_firewall_violations where username='APP_RUNTIME' order by occurred_at;

Rem Check audit records
pause;

select audit_type, dbusername, current_user, fw_action_name, fw_return_code,
sql_text, unified_audit_policies
from unified_audit_trail
where UNIFIED_AUDIT_POLICIES like '%APPLICATION_AUDIT_POLICY%'
order by event_timestamp;

-----------------------------------
Rem Purge violation logs and audit records
-----------------------------------

pause;

conn &dba_user/&userpwd
exec dbms_sql_firewall.purge_log('APP_RUNTIME', NULL, dbms_sql_firewall.VIOLATION_LOG);
exec DBMS_AUDIT_MGMT.CLEAN_AUDIT_TRAIL(audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_ALL, use_last_arch_timestamp=>FALSE);



-----------------------------------
Rem Cleanup
-----------------------------------

pause;

conn sys/&syspwd as sysdba
exec dbms_sql_firewall.disable;
drop user app_data cascade;
drop user app_runtime cascade;
drop user &dba_user cascade;
drop public synonym get_balance;
drop public synonym update_customer_addr;
drop public synonym customer_balances;

noaudit policy APPLICATION_AUDIT_POLICY;
drop audit policy APPLICATION_AUDIT_POLICY;
exec DBMS_AUDIT_MGMT.CLEAN_AUDIT_TRAIL(audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_ALL, use_last_arch_timestamp=>FALSE);

