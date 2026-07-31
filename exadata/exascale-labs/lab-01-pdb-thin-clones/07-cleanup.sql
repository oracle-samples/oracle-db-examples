-- Clean up Lab 01 objects.
--
-- Drops developer clones first, then the lab PDB snapshots.

@@../common/helpers.sql
@@../common/config.sql

WHENEVER SQLERROR EXIT SQL.SQLCODE

PROMPT Cleaning up Lab 01 PDBs
PROMPT Clusterware lifecycle before this SQL script:
PROMPT   ../common/manage-pdb-clusterware.sh stop-and-remove &&DEV_CLONE_CHILD,&&DEV_CLONE_2,&&DEV_CLONE_1
PROMPT SQL/DDL:
PROMPT   If &&DEV_CLONE_CHILD exists:
PROMPT     DROP PLUGGABLE DATABASE &&DEV_CLONE_CHILD INCLUDING DATAFILES;
PROMPT   If &&DEV_CLONE_2 exists:
PROMPT     DROP PLUGGABLE DATABASE &&DEV_CLONE_2 INCLUDING DATAFILES;
PROMPT   If &&DEV_CLONE_1 exists:
PROMPT     DROP PLUGGABLE DATABASE &&DEV_CLONE_1 INCLUDING DATAFILES;

DECLARE
    l_container_name VARCHAR2(128);

    PROCEDURE drop_pdb_if_exists(p_pdb_name IN VARCHAR2) IS
        l_count      NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO   l_count
        FROM   dba_pdbs
        WHERE  pdb_name = UPPER(p_pdb_name);

        IF l_count = 0 THEN
            dbms_output.put_line('Skipping ' || UPPER(p_pdb_name) || ': not found');
            RETURN;
        END IF;

        EXECUTE IMMEDIATE
            'DROP PLUGGABLE DATABASE ' || dbms_assert.simple_sql_name(UPPER(p_pdb_name)) ||
            ' INCLUDING DATAFILES';
    END;

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

    drop_pdb_if_exists('&&DEV_CLONE_CHILD');
    drop_pdb_if_exists('&&DEV_CLONE_2');
    drop_pdb_if_exists('&&DEV_CLONE_1');
END;
/

PROMPT SQL/DDL:
PROMPT   If &&SNAPSHOT_NAME exists:
PROMPT     ALTER SESSION SET CONTAINER = &&MAIN_PDB;
PROMPT     ALTER PLUGGABLE DATABASE DROP SNAPSHOT &&SNAPSHOT_NAME;
PROMPT     ALTER SESSION SET CONTAINER = &&ROOT_CONTAINER;

DEFINE DROP_SNAPSHOT_NAME = &&SNAPSHOT_NAME
COLUMN snapshot_action NEW_VALUE SNAPSHOT_ACTION NOPRINT

SELECT CASE
           WHEN COUNT(*) > 0 THEN 'drop-snapshot.sql'
           ELSE 'skip-snapshot.sql'
       END AS snapshot_action
FROM   dba_pdb_snapshots
WHERE  con_name = '&&MAIN_PDB'
AND    snapshot_name = '&&SNAPSHOT_NAME';

@@../common/&&SNAPSHOT_ACTION

PROMPT SQL/DDL:
PROMPT   If &&CONSISTENT_SNAPSHOT_NAME exists:
PROMPT     ALTER SESSION SET CONTAINER = &&MAIN_PDB;
PROMPT     ALTER PLUGGABLE DATABASE DROP SNAPSHOT &&CONSISTENT_SNAPSHOT_NAME;
PROMPT     ALTER SESSION SET CONTAINER = &&ROOT_CONTAINER;

DEFINE DROP_SNAPSHOT_NAME = &&CONSISTENT_SNAPSHOT_NAME
COLUMN snapshot_action NEW_VALUE SNAPSHOT_ACTION NOPRINT

SELECT CASE
           WHEN COUNT(*) > 0 THEN 'drop-snapshot.sql'
           ELSE 'skip-snapshot.sql'
       END AS snapshot_action
FROM   dba_pdb_snapshots
WHERE  con_name = '&&MAIN_PDB'
AND    snapshot_name = '&&CONSISTENT_SNAPSHOT_NAME';

@@../common/&&SNAPSHOT_ACTION

@@../common/verify-pdbs.sql
@@../common/verify-snapshots.sql
@@../common/verify-storage.sql

PROMPT Lab 01 cleanup complete
