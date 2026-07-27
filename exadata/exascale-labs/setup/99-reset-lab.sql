-- Reset the lab by dropping workshop PDBs.
--
-- Run from CDB$ROOT as a user with privileges to close and drop PDBs.
-- Oracle Managed Files is assumed; dropped PDBs include datafiles.

@@../common/helpers.sql
@@../common/config.sql

WHENEVER SQLERROR EXIT SQL.SQLCODE

PROMPT Resetting Exadata Exascale lab PDBs
PROMPT SQL/DDL:
PROMPT   For each existing lab clone or future PDB:
PROMPT     ALTER PLUGGABLE DATABASE <pdb_name> CLOSE IMMEDIATE INSTANCES = ALL;
PROMPT     DROP PLUGGABLE DATABASE <pdb_name> INCLUDING DATAFILES;

DECLARE
    l_container_name VARCHAR2(128);

    PROCEDURE drop_pdb_if_exists(p_pdb_name IN VARCHAR2) IS
        l_count      NUMBER;
        l_open_count NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO   l_count
        FROM   dba_pdbs
        WHERE  pdb_name = UPPER(p_pdb_name);

        IF l_count = 0 THEN
            dbms_output.put_line('Skipping ' || UPPER(p_pdb_name) || ': not found');
            RETURN;
        END IF;

        dbms_output.put_line('Dropping ' || UPPER(p_pdb_name));

        SELECT COUNT(*)
        INTO   l_open_count
        FROM   gv$pdbs
        WHERE  name = UPPER(p_pdb_name)
        AND    open_mode <> 'MOUNTED';

        IF l_open_count > 0 THEN
            EXECUTE IMMEDIATE
                'ALTER PLUGGABLE DATABASE ' || dbms_assert.simple_sql_name(UPPER(p_pdb_name)) ||
                ' CLOSE IMMEDIATE INSTANCES = ALL';
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

    drop_pdb_if_exists('&&CI_PDB');
    drop_pdb_if_exists('&&QA_PDB');
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
PROMPT   If &&MAIN_PDB exists:
PROMPT     ALTER PLUGGABLE DATABASE &&MAIN_PDB CLOSE IMMEDIATE INSTANCES = ALL;
PROMPT     DROP PLUGGABLE DATABASE &&MAIN_PDB INCLUDING DATAFILES;

DECLARE
    l_container_name VARCHAR2(128);

    PROCEDURE drop_pdb_if_exists(p_pdb_name IN VARCHAR2) IS
        l_count      NUMBER;
        l_open_count NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO   l_count
        FROM   dba_pdbs
        WHERE  pdb_name = UPPER(p_pdb_name);

        IF l_count = 0 THEN
            dbms_output.put_line('Skipping ' || UPPER(p_pdb_name) || ': not found');
            RETURN;
        END IF;

        dbms_output.put_line('Dropping ' || UPPER(p_pdb_name));

        SELECT COUNT(*)
        INTO   l_open_count
        FROM   gv$pdbs
        WHERE  name = UPPER(p_pdb_name)
        AND    open_mode <> 'MOUNTED';

        IF l_open_count > 0 THEN
            EXECUTE IMMEDIATE
                'ALTER PLUGGABLE DATABASE ' || dbms_assert.simple_sql_name(UPPER(p_pdb_name)) ||
                ' CLOSE IMMEDIATE INSTANCES = ALL';
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

    drop_pdb_if_exists('&&MAIN_PDB');
END;
/

@@../common/verify-pdbs.sql

PROMPT Lab reset complete
