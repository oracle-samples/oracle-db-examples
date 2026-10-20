-- Run as ADMIN on a separate Autonomous Database for the Entra demo.
-- Values are the DATABASE resource registration, not the Java client registration.
WHENEVER SQLERROR EXIT SQL.SQLCODE
SET VERIFY OFF
ACCEPT tenant_id CHAR PROMPT 'Entra tenant ID: '
ACCEPT database_application_id CHAR PROMPT 'Database application client ID: '
ACCEPT database_application_uri CHAR PROMPT 'Database application ID URI: '
BEGIN
  DBMS_CLOUD_ADMIN.ENABLE_EXTERNAL_AUTHENTICATION(
    type => 'AZURE_AD',
    params => JSON_OBJECT(
      'tenant_id' VALUE '&tenant_id',
      'application_id' VALUE '&database_application_id',
      'application_id_uri' VALUE '&database_application_uri'),
    force => FALSE);
END;
/
CREATE USER token_demo IDENTIFIED GLOBALLY AS 'AZURE_ROLE=TokenDemo.Connect';
GRANT CREATE SESSION TO token_demo;
SELECT name, value FROM v$parameter WHERE name = 'identity_provider_type';
UNDEFINE tenant_id
UNDEFINE database_application_id
UNDEFINE database_application_uri
