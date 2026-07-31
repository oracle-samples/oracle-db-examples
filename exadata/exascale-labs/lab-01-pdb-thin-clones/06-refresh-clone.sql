-- Refresh DEV_ALEX from the stable weekly snapshot.
--
-- Snapshot-based clones are independent read-write PDBs. This lab refreshes
-- the clone by dropping it and recreating it from the named SALES_MAIN snapshot.

@@../common/helpers.sql
@@../common/config.sql

WHENEVER SQLERROR EXIT SQL.SQLCODE

PROMPT Refreshing &&DEV_CLONE_1 from &&SNAPSHOT_NAME
PROMPT Clusterware lifecycle before this SQL script:
PROMPT   ../common/manage-pdb-clusterware.sh stop-and-remove &&DEV_CLONE_1
PROMPT SQL/DDL:
PROMPT   If &&DEV_CLONE_1 exists:
PROMPT     DROP PLUGGABLE DATABASE &&DEV_CLONE_1 INCLUDING DATAFILES;

DEFINE LAB_PAUSE_MESSAGE = "Press Return to close and drop &&DEV_CLONE_1 if it exists."
@@../common/&&LAB_PAUSE_SCRIPT

DECLARE
    l_container_name VARCHAR2(128);
    l_count          NUMBER;
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

    SELECT COUNT(*)
    INTO   l_count
    FROM   dba_pdbs
    WHERE  pdb_name = UPPER('&&DEV_CLONE_1');

    IF l_count > 0 THEN
        EXECUTE IMMEDIATE 'DROP PLUGGABLE DATABASE &&DEV_CLONE_1 INCLUDING DATAFILES';
    END IF;
END;
/

DEFINE LAB_PAUSE_MESSAGE = "Press Return to recreate &&DEV_CLONE_1 from snapshot &&SNAPSHOT_NAME."
@@../common/&&LAB_PAUSE_SCRIPT

PROMPT SQL/DDL:
PROMPT   CREATE PLUGGABLE DATABASE &&DEV_CLONE_1
PROMPT     FROM &&MAIN_PDB
PROMPT     USING SNAPSHOT &&SNAPSHOT_NAME
PROMPT     SNAPSHOT COPY;

CREATE PLUGGABLE DATABASE &&DEV_CLONE_1
    FROM &&MAIN_PDB
    USING SNAPSHOT &&SNAPSHOT_NAME
    SNAPSHOT COPY;

PROMPT Clusterware lifecycle after this SQL script:
PROMPT   ../common/manage-pdb-clusterware.sh ensure-and-start &&DEV_CLONE_1
PROMPT Then run 06-verify-refresh.sql.
