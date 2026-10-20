-- Run as ADMIN on an Autonomous Database dedicated to this OCI IAM demo.
-- This deliberately does not replace an existing external identity provider.
WHENEVER SQLERROR EXIT SQL.SQLCODE
SET VERIFY OFF
ACCEPT iam_principal CHAR PROMPT 'IAM user name (domain/name for a non-default domain): '
BEGIN
  DBMS_CLOUD_ADMIN.ENABLE_EXTERNAL_AUTHENTICATION(type => 'OCI_IAM');
END;
/
CREATE USER token_demo IDENTIFIED GLOBALLY AS 'IAM_PRINCIPAL_NAME=&iam_principal';
GRANT CREATE SESSION TO token_demo;
SELECT name, value FROM v$parameter WHERE name = 'identity_provider_type';
UNDEFINE iam_principal
-- Alternative shared mapping (use instead of the CREATE USER above):
-- CREATE USER token_demo IDENTIFIED GLOBALLY AS 'IAM_GROUP_NAME=domain/TokenDemoUsers';
-- Workload identities require a matching IAM dynamic group and shared mapping.
