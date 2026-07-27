-- Create the stable weekly PDB snapshot from SALES_MAIN.
--
-- Run from CDB$ROOT after setup has created and masked SALES_MAIN.

@@../common/helpers.sql
@@../common/config.sql

WHENEVER SQLERROR EXIT SQL.SQLCODE

PROMPT Creating snapshot &&SNAPSHOT_NAME for &&MAIN_PDB

DECLARE
    l_container_name VARCHAR2(128);
    l_main_pdbs      NUMBER;
    l_snapshots      NUMBER;
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
    INTO   l_main_pdbs
    FROM   dba_pdbs
    WHERE  pdb_name = UPPER('&&MAIN_PDB');

    IF l_main_pdbs = 0 THEN
        raise_application_error(
            -20001,
            'Cannot create snapshot &&SNAPSHOT_NAME because &&MAIN_PDB does not exist.'
        );
    END IF;

    SELECT COUNT(*)
    INTO   l_snapshots
    FROM   dba_pdb_snapshots
    WHERE  con_name = UPPER('&&MAIN_PDB')
    AND    snapshot_name = UPPER('&&SNAPSHOT_NAME');

    IF l_snapshots > 0 THEN
        raise_application_error(
            -20002,
            'Cannot create snapshot &&SNAPSHOT_NAME because it already exists for &&MAIN_PDB.'
        );
    END IF;
END;
/

DEFINE LAB_PAUSE_MESSAGE = "Press Return to create snapshot &&SNAPSHOT_NAME."
@@../common/&&LAB_PAUSE_SCRIPT

PROMPT SQL/DDL:
PROMPT   ALTER SESSION SET CONTAINER = &&MAIN_PDB;
PROMPT   ALTER PLUGGABLE DATABASE SNAPSHOT &&SNAPSHOT_NAME;
PROMPT   ALTER SESSION SET CONTAINER = &&ROOT_CONTAINER;

ALTER SESSION SET CONTAINER = &&MAIN_PDB;

ALTER PLUGGABLE DATABASE SNAPSHOT &&SNAPSHOT_NAME;

ALTER SESSION SET CONTAINER = &&ROOT_CONTAINER;

DEFINE LAB_PAUSE_MESSAGE = "Press Return to verify snapshot &&SNAPSHOT_NAME."
@@../common/&&LAB_PAUSE_SCRIPT

@@../common/verify-snapshots.sql

PROMPT PDB snapshot created
