-- Create independent developer thin clones from the SALES_MAIN snapshot.
--
-- Run from CDB$ROOT after 01-create-snapshot.sql.

@@../common/helpers.sql
@@../common/config.sql

WHENEVER SQLERROR EXIT SQL.SQLCODE

PROMPT Creating developer clones from snapshot &&SNAPSHOT_NAME

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

DEFINE LAB_PAUSE_MESSAGE = "Press Return to create &&DEV_CLONE_1 and &&DEV_CLONE_2."
@@../common/&&LAB_PAUSE_SCRIPT

PROMPT SQL/DDL:
PROMPT   CREATE PLUGGABLE DATABASE &&DEV_CLONE_1
PROMPT     FROM &&MAIN_PDB
PROMPT     USING SNAPSHOT &&SNAPSHOT_NAME
PROMPT     SNAPSHOT COPY;
PROMPT
PROMPT   CREATE PLUGGABLE DATABASE &&DEV_CLONE_2
PROMPT     FROM &&MAIN_PDB
PROMPT     USING SNAPSHOT &&SNAPSHOT_NAME
PROMPT     SNAPSHOT COPY;

CREATE PLUGGABLE DATABASE &&DEV_CLONE_1
    FROM &&MAIN_PDB
    USING SNAPSHOT &&SNAPSHOT_NAME
    SNAPSHOT COPY;

CREATE PLUGGABLE DATABASE &&DEV_CLONE_2
    FROM &&MAIN_PDB
    USING SNAPSHOT &&SNAPSHOT_NAME
    SNAPSHOT COPY;

PROMPT Clusterware lifecycle:
PROMPT   ../common/manage-pdb-clusterware.sh ensure-and-start &&DEV_CLONE_1,&&DEV_CLONE_2
PROMPT Then run 03-verify-clones.sql after the services are online.
