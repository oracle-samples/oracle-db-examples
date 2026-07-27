-- Capture a precise, manually named point after SALES_MAIN is refreshed in place.
--
-- This is intentionally separate from the interval-driven snapshot carousel.
-- Do not drop and recreate SALES_MAIN: doing so loses its carousel history.

@@../common/helpers.sql
@@../common/config.sql

WHENEVER SQLERROR EXIT SQL.SQLCODE

PROMPT Capturing precise post-refresh snapshot &&POST_REFRESH_SNAPSHOT_NAME for &&MAIN_PDB

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
            'Cannot capture a post-refresh snapshot because &&MAIN_PDB does not exist.'
        );
    END IF;

    SELECT COUNT(*)
    INTO   l_snapshots
    FROM   dba_pdb_snapshots
    WHERE  con_name = UPPER('&&MAIN_PDB')
    AND    snapshot_name = UPPER('&&POST_REFRESH_SNAPSHOT_NAME');

    IF l_snapshots > 0 THEN
        raise_application_error(
            -20002,
            'Snapshot &&POST_REFRESH_SNAPSHOT_NAME already exists. Use a new name or drop it explicitly when it is no longer needed.'
        );
    END IF;
END;
/

DEFINE LAB_PAUSE_MESSAGE = "Press Return to capture the precise post-refresh snapshot."
@@../common/&&LAB_PAUSE_SCRIPT

PROMPT SQL/DDL:
PROMPT   ALTER SESSION SET CONTAINER = &&MAIN_PDB;
PROMPT   ALTER PLUGGABLE DATABASE SNAPSHOT &&POST_REFRESH_SNAPSHOT_NAME;
PROMPT   ALTER SESSION SET CONTAINER = &&ROOT_CONTAINER;

ALTER SESSION SET CONTAINER = &&MAIN_PDB;

ALTER PLUGGABLE DATABASE SNAPSHOT &&POST_REFRESH_SNAPSHOT_NAME;

ALTER SESSION SET CONTAINER = &&ROOT_CONTAINER;

@@../common/verify-snapshots.sql

PROMPT Precise post-refresh snapshot captured. The interval carousel remains enabled.
