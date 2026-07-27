-- Clean up Lab 02 objects.
--
-- Drops the QA clone and disables the automated PDB snapshot carousel.
-- Drops the named precise post-refresh snapshot created by this lab.
-- Database-managed interval snapshots that already exist are reported but not
-- dropped.

@@../common/helpers.sql
@@../common/config.sql

WHENEVER SQLERROR EXIT SQL.SQLCODE

PROMPT Cleaning up Lab 02 PDBs and snapshot carousel
PROMPT SQL/DDL:
PROMPT   If &&QA_PDB exists:
PROMPT     ALTER PLUGGABLE DATABASE &&QA_PDB CLOSE IMMEDIATE INSTANCES = ALL;
PROMPT     DROP PLUGGABLE DATABASE &&QA_PDB INCLUDING DATAFILES;

DECLARE
    l_container_name VARCHAR2(128);
    l_count          NUMBER;
    l_open_count     NUMBER;
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
    WHERE  pdb_name = UPPER('&&QA_PDB');

    IF l_count = 0 THEN
        dbms_output.put_line('Skipping &&QA_PDB: not found');
    ELSE
        SELECT COUNT(*)
        INTO   l_open_count
        FROM   gv$pdbs
        WHERE  name = UPPER('&&QA_PDB')
        AND    open_mode <> 'MOUNTED';

        IF l_open_count > 0 THEN
            EXECUTE IMMEDIATE 'ALTER PLUGGABLE DATABASE &&QA_PDB CLOSE IMMEDIATE INSTANCES = ALL';
        END IF;

        EXECUTE IMMEDIATE 'DROP PLUGGABLE DATABASE &&QA_PDB INCLUDING DATAFILES';
    END IF;
END;
/

PROMPT SQL/DDL:
PROMPT   If &&MAIN_PDB exists:
PROMPT     ALTER SESSION SET CONTAINER = &&MAIN_PDB;
PROMPT     ALTER PLUGGABLE DATABASE SNAPSHOT MODE MANUAL;
PROMPT     ALTER SESSION SET CONTAINER = &&ROOT_CONTAINER;

COLUMN snapshot_carousel_action NEW_VALUE SNAPSHOT_CAROUSEL_ACTION NOPRINT

SELECT CASE
           WHEN COUNT(*) > 0 THEN 'disable-snapshot-carousel.sql'
           ELSE 'skip-snapshot-carousel.sql'
       END AS snapshot_carousel_action
FROM   dba_pdbs
WHERE  pdb_name = '&&MAIN_PDB';

@@../common/&&SNAPSHOT_CAROUSEL_ACTION

PROMPT SQL/DDL:
PROMPT   If &&POST_REFRESH_SNAPSHOT_NAME exists:
PROMPT     ALTER SESSION SET CONTAINER = &&MAIN_PDB;
PROMPT     ALTER PLUGGABLE DATABASE DROP SNAPSHOT &&POST_REFRESH_SNAPSHOT_NAME;
PROMPT     ALTER SESSION SET CONTAINER = &&ROOT_CONTAINER;

DEFINE DROP_SNAPSHOT_NAME = &&POST_REFRESH_SNAPSHOT_NAME
COLUMN snapshot_action NEW_VALUE SNAPSHOT_ACTION NOPRINT

SELECT CASE
           WHEN COUNT(*) > 0 THEN 'drop-snapshot.sql'
           ELSE 'skip-snapshot.sql'
       END AS snapshot_action
FROM   dba_pdb_snapshots
WHERE  con_name = '&&MAIN_PDB'
AND    snapshot_name = '&&POST_REFRESH_SNAPSHOT_NAME';

@@../common/&&SNAPSHOT_ACTION

PROMPT Existing snapshots are reported below. Disabling snapshot mode does not
PROMPT drop database-managed interval snapshots that have already been created.

@@../common/verify-pdbs.sql
@@../common/verify-snapshots.sql
@@../common/verify-storage.sql

PROMPT Lab 02 cleanup complete
