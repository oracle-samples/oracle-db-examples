-- Placeholder for site-specific masking of SALES_MAIN.
--
-- Run after SALES_MAIN has been created or refreshed from production.
-- This script intentionally does not include customer-specific masking logic.
-- Add local masking routines here after reviewing data classification,
-- privacy, and compliance requirements.

@@../common/helpers.sql
@@../common/config.sql

WHENEVER SQLERROR EXIT SQL.SQLCODE

PROMPT Masking placeholder for &&MAIN_PDB

DECLARE
    l_container_name VARCHAR2(128);
BEGIN
    SELECT sys_context('USERENV', 'CON_NAME')
    INTO   l_container_name
    FROM   dual;

    IF l_container_name <> '&&ROOT_CONTAINER' THEN
        raise_application_error(
            -20000,
            'This script must be run from &&ROOT_CONTAINER. Current container is ' ||
            l_container_name
        );
    END IF;
END;
/

DEFINE LAB_PAUSE_MESSAGE = "Press Return to switch into &&MAIN_PDB for masking."
@@../common/&&LAB_PAUSE_SCRIPT

PROMPT SQL/DDL:
PROMPT   ALTER SESSION SET CONTAINER = &&MAIN_PDB;

ALTER SESSION SET CONTAINER = &&MAIN_PDB;

-- Examples might include calls to local masking packages or Oracle Data Safe
-- workflows, depending on the environment. Do not commit real customer rules
-- or sensitive data examples to this repository.

PROMPT No masking logic has been executed.

DEFINE LAB_PAUSE_MESSAGE = "Press Return to return to &&ROOT_CONTAINER."
@@../common/&&LAB_PAUSE_SCRIPT

PROMPT SQL/DDL:
PROMPT   ALTER SESSION SET CONTAINER = &&ROOT_CONTAINER;

ALTER SESSION SET CONTAINER = &&ROOT_CONTAINER;

PROMPT Returned to &&ROOT_CONTAINER
