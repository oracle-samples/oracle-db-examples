-- Verify the common starting environment used by the labs.
--
-- Run from CDB$ROOT after creating and masking SALES_MAIN.

@@../common/helpers.sql
@@../common/config.sql

WHENEVER SQLERROR EXIT SQL.SQLCODE

PROMPT Environment summary
PROMPT Checking configuration and database identity for Lab 01 pre-flight

DECLARE
    l_current_user   VARCHAR2(128);
    l_container_name VARCHAR2(128);
    l_is_dba         VARCHAR2(5);
BEGIN
    SELECT sys_context('USERENV', 'CURRENT_USER'),
           sys_context('USERENV', 'CON_NAME'),
           sys_context('USERENV', 'ISDBA')
    INTO   l_current_user,
           l_container_name,
           l_is_dba
    FROM   dual;

    IF l_current_user = 'SYS' OR l_is_dba = 'TRUE' THEN
        dbms_output.put_line('PASS: Connected as ' || l_current_user || ' with administrative privileges.');
    ELSE
        raise_application_error(
            -20001,
            'This script must be run as SYSDBA or SYS. Current user is ' ||
            l_current_user
        );
    END IF;

    IF l_container_name <> '&&ROOT_CONTAINER' THEN
        raise_application_error(
            -20000,
            'This script must be run from &&ROOT_CONTAINER. Current container is ' ||
            l_container_name
        );
    END IF;

    dbms_output.put_line('PASS: Current container is ' || l_container_name || '.');
END;
/

DEFINE LAB_PAUSE_MESSAGE = "Press Return to display database identity and configuration."
@@../common/&&LAB_PAUSE_SCRIPT

COLUMN database_name FORMAT A18
COLUMN cdb_name FORMAT A18
COLUMN oracle_ai_database_version FORMAT A32
COLUMN compatible FORMAT A16
COLUMN current_container FORMAT A24
COLUMN current_user_name FORMAT A24

SELECT d.name AS database_name,
       d.name AS cdb_name,
       i.version_full AS oracle_ai_database_version,
       p.value AS compatible,
       sys_context('USERENV', 'CON_NAME') AS current_container,
       sys_context('USERENV', 'CURRENT_USER') AS current_user_name
FROM   v$database d
       CROSS JOIN v$instance i
       JOIN v$parameter p
         ON p.name = 'compatible';

PROMPT Configured workshop names

COLUMN setting FORMAT A18
COLUMN configured_value FORMAT A30

SELECT 'APP_NAME' AS setting, '&&APP_NAME' AS configured_value FROM dual
UNION ALL
SELECT 'MAIN_PDB', '&&MAIN_PDB' FROM dual
UNION ALL
SELECT 'SNAPSHOT_NAME', '&&SNAPSHOT_NAME' FROM dual
UNION ALL
SELECT 'CONSISTENT_SNAPSHOT_NAME', '&&CONSISTENT_SNAPSHOT_NAME' FROM dual
UNION ALL
SELECT 'DEV_CLONE_1', '&&DEV_CLONE_1' FROM dual
UNION ALL
SELECT 'DEV_CLONE_2', '&&DEV_CLONE_2' FROM dual
UNION ALL
SELECT 'DEV_CLONE_CHILD', '&&DEV_CLONE_CHILD' FROM dual
UNION ALL
SELECT 'QA_PDB', '&&QA_PDB' FROM dual
UNION ALL
SELECT 'CI_PDB', '&&CI_PDB' FROM dual;

PROMPT Oracle RAC instances

COLUMN host_name FORMAT A36
COLUMN version_full FORMAT A18

SELECT CASE
           WHEN COUNT(*) >= 2
           THEN 'PASS: Oracle RAC has ' || COUNT(*) || ' running instances visible in GV$INSTANCE.'
           ELSE 'WARN: GV$INSTANCE shows only ' || COUNT(*) || ' running instance. These labs assume Oracle RAC.'
       END AS status
FROM   gv$instance;

SELECT inst_id,
       instance_name,
       host_name,
       version_full,
       status
FROM   gv$instance
ORDER  BY inst_id;

PROMPT Confirm execution context

SELECT CASE
           WHEN sys_context('USERENV', 'CURRENT_USER') = 'SYS'
             OR sys_context('USERENV', 'ISDBA') = 'TRUE'
           THEN 'PASS: Connected as SYSDBA or SYS.'
           ELSE 'FAIL: Connect as SYSDBA or SYS before running Lab 01.'
       END AS status
FROM   dual;

SELECT CASE
           WHEN sys_context('USERENV', 'CON_NAME') = '&&ROOT_CONTAINER'
           THEN 'PASS: Running from &&ROOT_CONTAINER.'
           ELSE 'FAIL: Switch to &&ROOT_CONTAINER before running Lab 01.'
       END AS status
FROM   dual;

DEFINE LAB_PAUSE_MESSAGE = "Press Return to verify PDB configuration and RAC state."
@@../common/&&LAB_PAUSE_SCRIPT

PROMPT Verify PDB configuration

SELECT CASE
           WHEN COUNT(*) > 0
           THEN 'PASS: &&MAIN_PDB exists.'
           ELSE 'FAIL: &&MAIN_PDB does not exist. Run setup before Lab 01.'
       END AS status
FROM   dba_pdbs
WHERE  pdb_name = '&&MAIN_PDB';

SELECT CASE
           WHEN COUNT(s.snapshot_name) > 0
           THEN 'WARN: ' || snapshot_name || ' already exists. Lab 01 snapshot creation expects it to be absent.'
           ELSE 'PASS: ' || expected_snapshot || ' does not exist yet.'
       END AS status
FROM   (
           SELECT '&&SNAPSHOT_NAME' AS expected_snapshot FROM dual
           UNION ALL
           SELECT '&&CONSISTENT_SNAPSHOT_NAME' FROM dual
       ) e
       LEFT JOIN dba_pdb_snapshots s
         ON s.con_name = '&&MAIN_PDB'
        AND s.snapshot_name = e.expected_snapshot
GROUP  BY expected_snapshot, snapshot_name
ORDER  BY expected_snapshot;

SELECT CASE
           WHEN COUNT(p.pdb_name) > 0
           THEN 'WARN: ' || pdb_name || ' already exists. Lab 01 clone creation expects it to be absent.'
           ELSE 'PASS: ' || expected_pdb || ' does not exist yet.'
       END AS status
FROM   (
           SELECT '&&DEV_CLONE_1' AS expected_pdb FROM dual
           UNION ALL
           SELECT '&&DEV_CLONE_2' FROM dual
           UNION ALL
           SELECT '&&DEV_CLONE_CHILD' FROM dual
           UNION ALL
           SELECT '&&QA_PDB' FROM dual
           UNION ALL
           SELECT '&&CI_PDB' FROM dual
       ) e
       LEFT JOIN dba_pdbs p
         ON p.pdb_name = e.expected_pdb
GROUP  BY expected_pdb, pdb_name
ORDER  BY expected_pdb;

DEFINE LAB_PAUSE_MESSAGE = "Press Return to run shared verification reports."
@@../common/&&LAB_PAUSE_SCRIPT

@@../common/verify-pdbs.sql

PROMPT Verify PDB services

@@../common/verify-pdb-services.sql

PROMPT Verify snapshots

@@../common/verify-snapshots.sql

PROMPT Verify storage

@@../common/verify-storage.sql

PROMPT Verify datafiles

@@../common/verify-datafiles.sql

DEFINE LAB_PAUSE_MESSAGE = "Press Return to show the environment readiness summary."
@@../common/&&LAB_PAUSE_SCRIPT

PROMPT Summary

WITH checks AS (
    SELECT (SELECT COUNT(*)
            FROM   dba_pdbs
            WHERE  pdb_name = '&&MAIN_PDB') AS main_pdb_count,
           (SELECT COUNT(*)
           FROM   dba_pdb_snapshots
           WHERE  con_name = '&&MAIN_PDB'
            AND    snapshot_name IN ('&&SNAPSHOT_NAME',
                                     '&&CONSISTENT_SNAPSHOT_NAME')) AS snapshot_count,
           (SELECT COUNT(*)
            FROM   dba_pdbs
            WHERE  pdb_name IN ('&&DEV_CLONE_1',
                                '&&DEV_CLONE_2',
                                '&&DEV_CLONE_CHILD',
                                '&&QA_PDB',
                                '&&CI_PDB')) AS clone_count
    FROM   dual
)
SELECT CASE
           WHEN main_pdb_count = 1
            AND snapshot_count = 0
            AND clone_count = 0
           THEN 'READY: Environment is ready for Lab 01.'
           WHEN main_pdb_count = 0
           THEN 'NOT READY: &&MAIN_PDB is missing. Run setup before Lab 01.'
           ELSE 'NOT READY: Lab 01 objects already exist. Run the appropriate cleanup or reset script before retrying.'
       END AS lab_01_status
FROM   checks;

PROMPT Environment verification complete
