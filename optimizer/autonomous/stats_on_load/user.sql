--
-- Log into admin account and create a test user as follows
--
create user adwu1 identified by "choose your password";

grant ALTER SESSION to adwu1;
grant CREATE TABLE to adwu1;
grant CREATE VIEW to adwu1;
grant CREATE SESSION to adwu1;
--
grant select on v$session to adwu1;
grant select on v$sql_plan to adwu1;
grant select on v$sql to adwu1;
